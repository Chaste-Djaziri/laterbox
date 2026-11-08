// laterbox-web/src/lib/utils/settingsNavigation.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { SETTINGS_SECTIONS, isSettingsSectionId, getSettingsSection } from './settingsNavigation';

test('all settings categories have unique, deep-linkable route identifiers', () => {
  const ids = SETTINGS_SECTIONS.map(section => section.id);
  assert.equal(new Set(ids).size, ids.length);
  assert.deepEqual(ids, [
    'account', 'preferences', 'notifications', 'sync',
    'backup', 'apps', 'billing', 'updates', 'legal',
  ]);
  for (const id of ids) {
    assert.equal(isSettingsSectionId(id), true);
    assert.ok(getSettingsSection(id).label);
    assert.ok(getSettingsSection(id).description);
  }
  assert.equal(isSettingsSectionId('overview'), false);
  assert.equal(isSettingsSectionId('invalid'), false);
  assert.equal(isSettingsSectionId('__proto__'), false);
});
