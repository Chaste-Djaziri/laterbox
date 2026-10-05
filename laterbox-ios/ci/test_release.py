import datetime
import unittest
from unittest.mock import patch
import urllib.error
from app_store import release_numbers, existing_app, APP_ID, BUNDLE
from signing import validate, TEAM, GROUP

class ReleaseTests(unittest.TestCase):
    def test_existing_app_checks_identity(self):
        with patch('app_store.request', return_value={'data': {'id': APP_ID, 'attributes': {'bundleId': BUNDLE}}}) as fetch:
            self.assertEqual(existing_app(), APP_ID)
            fetch.assert_called_once_with('/v1/apps/' + APP_ID)
        with patch('app_store.request', return_value={'data': {'id': APP_ID, 'attributes': {'bundleId': 'wrong.bundle'}}}):
            with self.assertRaisesRegex(RuntimeError, 'identity'): existing_app()
    def test_app_access_failure_reports_status(self):
        with patch('app_store.request', side_effect=urllib.error.HTTPError('https://api.appstoreconnect.apple.com', 403, 'Forbidden', {}, None)):
            with self.assertRaisesRegex(RuntimeError, 'HTTP 403'): existing_app()

    def test_numbers_exceed_legacy_builds_and_closed_versions(self):
        version, build = release_numbers({'version':'1.0.173','buildNumber':175},
                                        [{'attributes':{'version':'180.2'}}],
                                        [{'attributes':{'versionString':'1.0.173'}}])
        self.assertEqual((version, build), ('1.0.174', '181'))
    def test_new_repository_version_is_preserved(self):
        self.assertEqual(release_numbers({'version':'1.0.173','buildNumber':175}, [], []), ('1.0.173','176'))
    def test_profile_rejects_old_identity_missing_group_and_development(self):
        bundle = 'pro.micorp.laterbox.ShareExtension'
        profile = {'ExpirationDate':datetime.datetime(2030,1,1), 'TeamIdentifier':[TEAM], 'Name':'Distribution',
                   'Entitlements':{'application-identifier':TEAM+'.'+bundle,'com.apple.security.application-groups':[GROUP]}}
        self.assertEqual(validate(profile, bundle), 'Distribution')
        for bad in [ {'application-identifier':TEAM+'.wrong'}, {'com.apple.security.application-groups':[]}, {'get-task-allow':True} ]:
            with self.assertRaises(ValueError): validate({**profile, 'Entitlements':{**profile['Entitlements'], **bad}}, bundle)
        with self.assertRaises(ValueError): validate({**profile, 'ExpirationDate':datetime.datetime(2020,1,1)}, bundle)

if __name__ == '__main__': unittest.main()
