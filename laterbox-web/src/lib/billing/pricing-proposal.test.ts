// laterbox-web/src/lib/billing/pricing-proposal.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { PROPOSED_LATERBOX_PLANS, scenarioContribution } from './pricing-proposal';

const baseline = { period: 'month' as const, quotaUtilization: 1,
  affiliateRate: 0.15, extraVariableFeeRate: 0 };

test('draft capacity ladder extends to 2 TiB without changing existing Plus/Vault prices', () => {
  assert.deepEqual(PROPOSED_LATERBOX_PLANS.map(p => p.quotaGiB),
    [10, 50, 100, 250, 500, 1024, 2048]);
  assert.deepEqual(PROPOSED_LATERBOX_PLANS.slice(0, 1).map(p => p.monthUsd), [2.99]);
  assert.equal(PROPOSED_LATERBOX_PLANS.find(p => p.quotaGiB === 100)?.monthUsd, 6.99);
  assert.equal(PROPOSED_LATERBOX_PLANS.at(-1)?.monthUsd, 69.99);
});

test('proposed standard subscription tiers retain positive contribution even at quota-full usage', () => {
  for (const plan of PROPOSED_LATERBOX_PLANS) {
    const month = scenarioContribution(plan, baseline);
    const year = scenarioContribution(plan, { ...baseline, period: 'year' });
    assert.ok(month.contributionUsd > 0, `monthly ${plan.name} would be loss-making`);
    assert.ok(year.contributionUsd > 0, `annual ${plan.name} would be loss-making`);
    assert.ok(month.r2StorageUsd > 0);
  }
});

test('higher physical storage use lowers contribution predictably', () => {
  const plan = PROPOSED_LATERBOX_PLANS.at(-1)!;
  const low = scenarioContribution(plan, { ...baseline, quotaUtilization: .35 });
  const high = scenarioContribution(plan, baseline);
  assert.ok(low.contributionUsd > high.contributionUsd);
});

test('affiliates receive less after qualification, improving future margin', () => {
  const plan = PROPOSED_LATERBOX_PLANS[4];
  const launch = scenarioContribution(plan, baseline);
  const ongoing = scenarioContribution(plan, { ...baseline, affiliateRate: .10 });
  assert.ok(ongoing.commissionUsd < launch.commissionUsd);
  assert.ok(ongoing.contributionUsd > launch.contributionUsd);
});

test('material international fee stress must not be ignored', () => {
  const plan = PROPOSED_LATERBOX_PLANS.at(-1)!;
  const ordinary = scenarioContribution(plan, baseline);
  const stressed = scenarioContribution(plan, { ...baseline, extraVariableFeeRate: .0275 });
  assert.ok(stressed.contributionUsd < ordinary.contributionUsd);
  assert.ok(stressed.contributionUsd > 0);
});

test('scenario bounds protect against nonsensical inputs', () => {
  assert.throws(() => scenarioContribution(PROPOSED_LATERBOX_PLANS[0], {
    ...baseline, quotaUtilization: 1.3,
  }), RangeError);
});
