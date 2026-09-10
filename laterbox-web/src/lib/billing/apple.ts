import {
  Environment,
  SignedDataVerifier,
  type JWSRenewalInfoDecodedPayload,
  type JWSTransactionDecodedPayload,
  type ResponseBodyV2DecodedPayload,
} from '@apple/app-store-server-library';

export const APPLE_PRODUCTS = new Set([
  'com.laterbox.pro.monthly',
  'com.laterbox.pro.annual',
]);

const bundleId = process.env.APPLE_BUNDLE_ID || 'pro.micorp.laterbox';

function certificates(): Buffer[] {
  const encoded = process.env.APPLE_ROOT_CERTIFICATES_BASE64;
  if (!encoded) throw new Error('Apple root certificates are not configured.');
  return encoded
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean)
    .map((value) => Buffer.from(value, 'base64'));
}

function verifier(environment: Environment): SignedDataVerifier {
  const appAppleId = process.env.APPLE_APP_ID
    ? Number(process.env.APPLE_APP_ID)
    : undefined;
  if (environment === Environment.PRODUCTION && !appAppleId) {
    throw new Error('APPLE_APP_ID is required for production verification.');
  }
  return new SignedDataVerifier(
    certificates(),
    true,
    environment,
    bundleId,
    environment === Environment.PRODUCTION ? appAppleId : undefined,
  );
}

async function tryEnvironments<T>(action: (value: SignedDataVerifier) => Promise<T>) {
  let lastError: unknown;
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      return await action(verifier(environment));
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError instanceof Error ? lastError : new Error('Apple signature verification failed.');
}

export function verifyAppleTransaction(signedTransaction: string) {
  return tryEnvironments((value) => value.verifyAndDecodeTransaction(signedTransaction));
}

export function verifyAppleNotification(signedPayload: string) {
  return tryEnvironments((value) => value.verifyAndDecodeNotification(signedPayload));
}

export async function decodeNotificationData(payload: ResponseBodyV2DecodedPayload): Promise<{
  transaction: JWSTransactionDecodedPayload | null;
  renewal: JWSRenewalInfoDecodedPayload | null;
}> {
  const signedTransaction = payload.data?.signedTransactionInfo;
  const signedRenewal = payload.data?.signedRenewalInfo;
  const environment = payload.data?.environment === Environment.PRODUCTION
    ? Environment.PRODUCTION
    : Environment.SANDBOX;
  const value = verifier(environment);
  return {
    transaction: signedTransaction
      ? await value.verifyAndDecodeTransaction(signedTransaction)
      : null,
    renewal: signedRenewal
      ? await value.verifyAndDecodeRenewalInfo(signedRenewal)
      : null,
  };
}

export function assertAppleTransaction(
  transaction: JWSTransactionDecodedPayload,
  expectedUserId?: string,
) {
  if (!transaction.productId || !APPLE_PRODUCTS.has(transaction.productId)) {
    throw new Error('Unknown LaterBox App Store product.');
  }
  if (!transaction.originalTransactionId || !transaction.transactionId) {
    throw new Error('Apple transaction identifiers are missing.');
  }
  if (!transaction.appAccountToken) {
    throw new Error('Apple transaction is not linked to a LaterBox account.');
  }
  if (expectedUserId && transaction.appAccountToken.toLowerCase() !== expectedUserId.toLowerCase()) {
    throw new Error('Apple transaction belongs to another LaterBox account.');
  }
  if (transaction.bundleId && transaction.bundleId !== bundleId) {
    throw new Error('Apple transaction bundle does not match LaterBox.');
  }
}

export function appleSubscriptionState(
  transaction: JWSTransactionDecodedPayload,
  renewal?: JWSRenewalInfoDecodedPayload | null,
) {
  const now = Date.now();
  const expiresAt = transaction.expiresDate ?? 0;
  const revoked = Boolean(transaction.revocationDate);
  const graceEnds = renewal?.gracePeriodExpiresDate ?? 0;
  const inGrace = Boolean(renewal?.isInBillingRetryPeriod && graceEnds > now);
  const trial = transaction.offerType === 1 && expiresAt > now;
  const active = !revoked && expiresAt > now;
  const status = revoked
    ? 'canceled'
    : inGrace
      ? 'past_due'
      : trial
        ? 'trialing'
        : active
          ? 'active'
          : 'canceled';
  return {
    status,
    periodStart: transaction.purchaseDate
      ? new Date(transaction.purchaseDate).toISOString()
      : null,
    periodEnd: expiresAt ? new Date(expiresAt).toISOString() : null,
    graceEnd: graceEnds ? new Date(graceEnds).toISOString() : null,
    willCancel: renewal?.autoRenewStatus === 0,
  } as const;
}
