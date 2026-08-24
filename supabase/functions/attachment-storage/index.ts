import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from "npm:@aws-sdk/client-s3@3.888.0";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@3.888.0";
import { handleInternalHealthCheck } from "../_shared/health.ts";

const allowedOrigins = new Set([
  "https://laterbox.dev",
  "https://www.laterbox.dev",
  "https://laterbox.micorp.pro",
  "https://laterbox.pages.dev",
  "https://app.laterbox.com",
  "http://localhost:8080",
  "http://localhost:3000",
  "http://localhost:5173",
]);

const maxBytes = 5 * 1024 * 1024 * 1024; // 5 GiB

type AttachmentBody = {
  action?: unknown;
  attachmentId?: unknown;
  itemId?: unknown;
  originalFileName?: unknown;
  extension?: unknown;
  mimeType?: unknown;
  byteSize?: unknown;
  sha256?: unknown;
};

function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return true; // Native clients (Dart/macOS/iOS/Android)
  if (allowedOrigins.has(origin)) return true;
  if (/^https:\/\/([a-z0-9-]+\.)?laterbox\.pages\.dev$/.test(origin)) return true;
  if (/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) return true;
  return false;
}

const corsHeaders = (request: Request): HeadersInit => {
  const origin = request.headers.get("origin");
  const allowOrigin = isAllowedOrigin(origin) ? (origin ?? "*") : "*";
  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, x-amz-meta-sha256, x-amz-meta-attachment-id, x-amz-meta-user-id",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    Vary: "Origin",
  };
};

const json = (request: Request, data: unknown, status: number): Response =>
  Response.json(data, {
    status,
    headers: corsHeaders(request),
  });

const handler = async (request: Request): Promise<Response> => {
  const healthResponse = handleInternalHealthCheck(request, "attachment-storage");
  if (healthResponse) {
    return healthResponse;
  }

  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }
  if (request.method !== "POST") {
    return json(request, { error: "Method not allowed" }, 405);
  }

  const token = bearerToken(request.headers.get("authorization"));
  if (!token) return json(request, { error: "Authentication required" }, 401);
  const userId = await authenticateUser(token);
  if (!userId) return json(request, { error: "Invalid access token" }, 401);

  let body: AttachmentBody;
  try {
    body = await request.json();
  } catch {
    return json(request, { error: "Invalid JSON body" }, 400);
  }

  try {
    const action = requireString(body.action, "action");
    switch (action) {
      case "prepare-upload":
        return await prepareUpload(request, userId, body);
      case "complete-upload":
        return await completeUpload(request, userId, body);
      case "prepare-download":
        return await prepareDownload(request, userId, body);
      case "delete":
        return await deleteAttachment(request, userId, body);
      default:
        return json(request, { error: "Unsupported action" }, 400);
    }
  } catch (error) {
    if (error instanceof RequestError) {
      return json(request, { error: error.message }, error.status);
    }
    console.error("attachment-storage failed", error);
    return json(request, { error: "Attachment storage failed" }, 502);
  }
};

async function prepareUpload(
  request: Request,
  userId: string,
  body: AttachmentBody,
): Promise<Response> {
  const attachment = validateAttachment(body);
  await verifyItemOwnership(attachment.itemId, userId);
  const objectKey = objectKeyFor(userId, attachment.id, attachment.extension);
  const uploadUrl = await getSignedUrl(
    r2Client(),
    new PutObjectCommand({
      Bucket: requiredEnv("R2_BUCKET"),
      Key: objectKey,
      ContentType: attachment.mimeType,
      Metadata: {
        sha256: attachment.sha256,
        "attachment-id": attachment.id,
        "user-id": userId,
      },
    }),
    {
      expiresIn: signedUrlTtl(),
      unhoistableHeaders: new Set([
        "x-amz-meta-sha256",
        "x-amz-meta-attachment-id",
        "x-amz-meta-user-id",
      ]),
    },
  );
  return json(
    request,
    { objectKey, uploadUrl, expiresIn: signedUrlTtl() },
    200,
  );
}

async function completeUpload(
  request: Request,
  userId: string,
  body: AttachmentBody,
): Promise<Response> {
  const attachment = validateAttachment(body);
  await verifyItemOwnership(attachment.itemId, userId);
  const objectKey = objectKeyFor(userId, attachment.id, attachment.extension);
  const head = await r2Client().send(
    new HeadObjectCommand({ Bucket: requiredEnv("R2_BUCKET"), Key: objectKey }),
  );
  if (
    head.ContentLength !== attachment.byteSize ||
    head.ContentType !== attachment.mimeType ||
    head.Metadata?.sha256 !== attachment.sha256 ||
    head.Metadata?.["attachment-id"] !== attachment.id ||
    head.Metadata?.["user-id"] !== userId
  ) {
    throw new RequestError("Uploaded object verification failed", 409);
  }
  return json(request, { objectKey, verified: true }, 200);
}

async function prepareDownload(
  request: Request,
  userId: string,
  body: AttachmentBody,
): Promise<Response> {
  const attachmentId = requireUuid(body.attachmentId, "attachmentId");
  const row = await ownedAttachment(attachmentId, userId);
  if (!row?.r2_object_key) {
    throw new RequestError("Attachment is not available remotely", 404);
  }
  const downloadUrl = await getSignedUrl(
    r2Client(),
    new GetObjectCommand({
      Bucket: requiredEnv("R2_BUCKET"),
      Key: row.r2_object_key,
    }),
    { expiresIn: signedUrlTtl() },
  );
  return json(
    request,
    { objectKey: row.r2_object_key, downloadUrl, expiresIn: signedUrlTtl() },
    200,
  );
}

async function deleteAttachment(
  request: Request,
  userId: string,
  body: AttachmentBody,
): Promise<Response> {
  const attachmentId = requireUuid(body.attachmentId, "attachmentId");
  const row = await ownedAttachment(attachmentId, userId);
  let objectKey = row?.r2_object_key;
  if (!objectKey && typeof body.extension === "string" && body.extension.length > 0) {
    objectKey = objectKeyFor(userId, attachmentId, body.extension.toLowerCase());
  }
  if (objectKey) {
    try {
      await r2Client().send(
        new DeleteObjectCommand({
          Bucket: requiredEnv("R2_BUCKET"),
          Key: objectKey,
        }),
      );
    } catch (error) {
      console.warn("R2 deleteObject warning:", error);
    }
  }
  return json(request, { deleted: true }, 200);
}

type ValidAttachment = {
  id: string;
  itemId: string;
  originalFileName: string;
  extension: string;
  mimeType: string;
  byteSize: number;
  sha256: string;
};

function validateAttachment(body: AttachmentBody): ValidAttachment {
  const id = requireUuid(body.attachmentId, "attachmentId");
  const itemId = requireUuid(body.itemId, "itemId");
  const originalFileName = requireString(
    body.originalFileName,
    "originalFileName",
  );
  const extension = requireString(body.extension, "extension").toLowerCase();
  const mimeType = requireString(body.mimeType, "mimeType").toLowerCase();
  const byteSize = body.byteSize;
  const sha256 = requireString(body.sha256, "sha256").toLowerCase();
  if (extension.length === 0 || extension.length > 50) {
    throw new RequestError("Invalid file extension", 400);
  }
  if (mimeType.length === 0 || mimeType.length > 128) {
    throw new RequestError("Invalid mime type", 400);
  }
  if (
    !Number.isInteger(byteSize) || Number(byteSize) < 1 ||
    Number(byteSize) > maxBytes
  ) {
    throw new RequestError("Invalid attachment size", 400);
  }
  if (!/^[0-9a-f]{64}$/.test(sha256)) {
    throw new RequestError("Invalid SHA-256", 400);
  }
  if (originalFileName.length > 255) {
    throw new RequestError("Original filename is too long", 400);
  }
  return {
    id,
    itemId,
    originalFileName,
    extension,
    mimeType,
    byteSize: Number(byteSize),
    sha256,
  };
}

async function authenticateUser(token: string): Promise<string | null> {
  const response = await fetch(`${requiredEnv("SUPABASE_URL")}/auth/v1/user`, {
    headers: {
      apikey: requiredEnv("SUPABASE_ANON_KEY"),
      authorization: `Bearer ${token}`,
    },
  });
  if (!response.ok) return null;
  const user = await response.json();
  return typeof user?.id === "string" ? user.id : null;
}

async function verifyItemOwnership(itemId: string, userId: string): Promise<void> {
  const rows = await adminGet(
    `items?select=id,user_id&id=eq.${encodeURIComponent(itemId)}`,
  );
  if (Array.isArray(rows) && rows.length > 0) {
    if (rows[0]?.user_id !== userId) {
      throw new RequestError("Unauthorized item ownership", 403);
    }
  }
  // When an attachment is being uploaded for a new item, the item may not
  // be inserted into the remote database yet (as attachments upload first).
}

async function ownedAttachment(
  attachmentId: string,
  userId: string,
): Promise<{ r2_object_key: string | null } | null> {
  const rows = await adminGet(
    `attachments?select=r2_object_key&id=eq.${
      encodeURIComponent(attachmentId)
    }&user_id=eq.${encodeURIComponent(userId)}`,
  );
  return Array.isArray(rows) && rows.length === 1 ? rows[0] : null;
}

async function adminGet(path: string): Promise<unknown> {
  const serviceKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const response = await fetch(
    `${requiredEnv("SUPABASE_URL")}/rest/v1/${path}`,
    {
      headers: { apikey: serviceKey, authorization: `Bearer ${serviceKey}` },
    },
  );
  if (!response.ok) {
    throw new Error(`Supabase query failed with ${response.status}`);
  }
  return await response.json();
}

function r2Client(): S3Client {
  return new S3Client({
    region: Deno.env.get("R2_REGION") ?? "auto",
    endpoint: requiredEnv("R2_ENDPOINT"),
    requestChecksumCalculation: "WHEN_REQUIRED",
    credentials: {
      accessKeyId: requiredEnv("R2_ACCESS_KEY_ID"),
      secretAccessKey: requiredEnv("R2_SECRET_ACCESS_KEY"),
    },
  });
}

function objectKeyFor(
  userId: string,
  attachmentId: string,
  extension: string,
): string {
  return `users/${userId}/attachments/${attachmentId}/original.${extension}`;
}

function signedUrlTtl(): number {
  const parsed = Number(Deno.env.get("R2_SIGNED_URL_TTL_SECONDS") ?? "900");
  return Number.isInteger(parsed) && parsed >= 60 && parsed <= 3600
    ? parsed
    : 900;
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required secret ${name}`);
  return value;
}

function bearerToken(value: string | null): string | null {
  return value?.match(/^Bearer\s+(.+)$/i)?.[1] ?? null;
}

function requireString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new RequestError(`Invalid ${name}`, 400);
  }
  return value.trim();
}

function requireUuid(value: unknown, name: string): string {
  const parsed = requireString(value, name).toLowerCase();
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      .test(parsed)
  ) {
    throw new RequestError(`Invalid ${name}`, 400);
  }
  return parsed;
}

class RequestError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

export { handler, objectKeyFor, validateAttachment };

if (import.meta.main) Deno.serve(handler);
