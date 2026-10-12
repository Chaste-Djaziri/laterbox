import {
  Environment,
  SignedDataVerifier,
  type JWSRenewalInfoDecodedPayload,
  type JWSTransactionDecodedPayload,
  type ResponseBodyV2DecodedPayload,
} from '@apple/app-store-server-library';

export class AppleBillingError extends Error {
  constructor(public code: string, message: string, public status = 422) {
    super(message);
  }
}

export const APPLE_PRODUCTS = new Set([
  'com.laterbox.pro.monthly',
  'com.laterbox.pro.annual',
]);

const bundleId = process.env.APPLE_BUNDLE_ID || 'pro.micorp.laterbox';

function certificates(): Buffer[] {
  const encoded = process.env.APPLE_ROOT_CERTIFICATES_BASE64;
  if (!encoded) throw new AppleBillingError('configuration_unavailable', 'Apple root certificates are not configured.', 503);
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
  if (environment === Environment.PRODUCTION && (!appAppleId || !Number.isSafeInteger(appAppleId) || appAppleId <= 0)) {
    throw new AppleBillingError('configuration_unavailable', 'APPLE_APP_ID is required for production verification.', 503);
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
  let configurationError: AppleBillingError | undefined;
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      return await action(verifier(environment));
    } catch (error) {
      lastError = error;
      if (error instanceof AppleBillingError) configurationError = error;
    }
  }
  if (configurationError) throw configurationError;
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
  allowUnlinked = false,
) {
  if (!transaction.productId || !APPLE_PRODUCTS.has(transaction.productId)) {
    throw new Error('Unknown LaterBox App Store product.');
  }
  if (!transaction.originalTransactionId || !transaction.transactionId) {
    throw new Error('Apple transaction identifiers are missing.');
  }
  if (transaction.environment !== Environment.PRODUCTION && transaction.environment !== Environment.SANDBOX) {
    throw new AppleBillingError('unsupported_environment', 'Only App Store and TestFlight purchases can enable cloud access.');
  }
  if (!transaction.appAccountToken && !allowUnlinked) {
    throw new AppleBillingError('account_token_missing', 'This purchase is not linked to a LaterBox account. Contact support for purchase recovery.');
  }
  if (expectedUserId && transaction.appAccountToken?.toLowerCase() !== expectedUserId.toLowerCase()) {
    throw new AppleBillingError('account_mismatch', 'Sign in to the LaterBox account used for this purchase.', 403);
  }
  if (transaction.bundleId && transaction.bundleId !== bundleId) {
    throw new Error('Apple transaction bundle does not match LaterBox.');
  }
}

export function verifyAppleTransactionInEnvironment(value: string, environment: Environment) {
  return verifier(environment).verifyAndDecodeTransaction(value);
}

export function verifyAppleRenewalInEnvironment(value: string, environment: Environment) {
  return verifier(environment).verifyAndDecodeRenewalInfo(value);
}

export function appleSubscriptionState(
  transaction: JWSTransactionDecodedPayload,
  renewal?: JWSRenewalInfoDecodedPayload | null,
) {
  const now = Date.now();
  const expiresAt = transaction.expiresDate ?? 0;
  const revoked = Boolean(transaction.revocationDate);
  const graceEnds = renewal?.gracePeriodExpiresDate ?? 0;
  const inGrace = !revoked && Boolean(renewal?.isInBillingRetryPeriod && graceEnds > now);
  const trial = transaction.offerDiscountType === 'FREE_TRIAL' && expiresAt > now;
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
    periodEnd: revoked
      ? new Date(Math.min(transaction.revocationDate!, expiresAt || transaction.revocationDate!)).toISOString()
      : expiresAt ? new Date(expiresAt).toISOString() : null,
    graceEnd: graceEnds ? new Date(graceEnds).toISOString() : null,
    willCancel: renewal?.autoRenewStatus === 0,
  } as const;
}
