import { CreateBucketCommand, HeadBucketCommand, S3Client } from "@aws-sdk/client-s3";

const bucket = process.env.MINIO_BUCKET;
if (!bucket) throw new Error("MINIO_BUCKET is required");

const client = new S3Client({
  endpoint: "http://minio:9000",
  region: "us-east-1",
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.MINIO_ROOT_USER ?? "",
    secretAccessKey: process.env.MINIO_ROOT_PASSWORD ?? "",
  },
});

for (let attempt = 1; attempt <= 30; attempt += 1) {
  try {
    await client.send(new HeadBucketCommand({ Bucket: bucket }));
    console.log(`Local MinIO bucket ${bucket} is ready.`);
    process.exit(0);
  } catch (error) {
    if (error?.Code !== "XMinioServerNotInitialized") {
      try {
        await client.send(new CreateBucketCommand({ Bucket: bucket }));
        console.log(`Local MinIO bucket ${bucket} is ready.`);
        process.exit(0);
      } catch (createError) {
        if (createError?.Code !== "XMinioServerNotInitialized") throw createError;
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
}

throw new Error("MinIO did not finish initializing within 30 seconds.");
