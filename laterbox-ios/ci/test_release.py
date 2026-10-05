import datetime
import unittest
from app_store import release_numbers
from signing import validate, TEAM, GROUP

class ReleaseTests(unittest.TestCase):
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
