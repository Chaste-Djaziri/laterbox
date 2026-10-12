import { AppStoreServerAPIClient, Environment, type JWSTransactionDecodedPayload, type JWSRenewalInfoDecodedPayload, type StatusResponse } from '@apple/app-store-server-library';
import { AppleBillingError, assertAppleTransaction, verifyAppleTransactionInEnvironment, verifyAppleRenewalInEnvironment } from './apple';

export function appleServerClient(environment: Environment) {
  const key = process.env.APPLE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  const keyId = process.env.APPLE_KEY_ID;
  const issuer = process.env.APPLE_ISSUER_ID;
  if (!key || !keyId || !issuer) throw new AppleBillingError('linking_unavailable', 'Device Pro is active. Account connection is temporarily unavailable; please retry later.', 503);
  return new AppStoreServerAPIClient(key, keyId, issuer, process.env.APPLE_BUNDLE_ID || 'pro.micorp.laterbox', environment);
}

type StatusDependencies = {
  status: (id: string, environment: Environment) => Promise<StatusResponse>;
  transaction: (jws: string, environment: Environment) => Promise<JWSTransactionDecodedPayload>;
  renewal: (jws: string, environment: Environment) => Promise<JWSRenewalInfoDecodedPayload>;
};
const dependencies: StatusDependencies = {
  status: (id, env) => appleServerClient(env).getAllSubscriptionStatuses(id),
  transaction: verifyAppleTransactionInEnvironment,
  renewal: verifyAppleRenewalInEnvironment,
};

/** Receipt possession alone must not grant a trial that Apple has since refunded. */
export async function currentAppleSubscription(proof: JWSTransactionDecodedPayload, deps = dependencies) {
  assertAppleTransaction(proof);
  if (proof.inAppOwnershipType === 'FAMILY_SHARED') throw new AppleBillingError('shared_purchase', 'Family-shared purchases can be restored on this device; only the purchaser can connect an account.', 409);
  const environment = proof.environment as Environment;
  const response = await deps.status(proof.originalTransactionId!, environment);
  if (response.environment !== environment) throw new AppleBillingError('verification_failed', 'Apple subscription environment does not match.');
  for (const group of response.data ?? []) {
    for (const item of group.lastTransactions ?? []) {
      if (item.originalTransactionId !== proof.originalTransactionId || !item.signedTransactionInfo) continue;
      const transaction = await deps.transaction(item.signedTransactionInfo, environment);
      assertAppleTransaction(transaction);
      if (transaction.originalTransactionId !== proof.originalTransactionId || transaction.appAccountToken?.toLowerCase() !== proof.appAccountToken?.toLowerCase()) {
        throw new AppleBillingError('account_mismatch', 'This purchase is associated with another account.', 409);
      }
      const renewal = item.signedRenewalInfo ? await deps.renewal(item.signedRenewalInfo, environment) : null;
      if (renewal && renewal.originalTransactionId !== transaction.originalTransactionId) throw new AppleBillingError('verification_failed', 'Apple renewal does not match this subscription.');
      if (item.status === 5 && !transaction.revocationDate) throw new AppleBillingError('linking_unavailable', 'Apple reports revoked access. Please restore purchases and retry.', 503);
      if (item.status === 4 && !renewal?.gracePeriodExpiresDate) throw new AppleBillingError('linking_unavailable', 'Apple grace period information is unavailable. Please retry.', 503);
      const stateAt = new Date(Math.max(transaction.signedDate ?? 0, renewal?.signedDate ?? 0)).toISOString();
      return { transaction, renewal, stateAt };
    }
  }
  throw new AppleBillingError('purchase_not_found', 'Apple could not find this subscription. Restore purchases and retry.', 409);
}
