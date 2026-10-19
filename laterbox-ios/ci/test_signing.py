import datetime
import unittest

from signing import GROUP, TARGETS, TEAM, validate


class SigningProfileTests(unittest.TestCase):
    def profile(self, bundle, apple_sign_in=False):
        entitlements = {
            "application-identifier": TEAM + "." + bundle,
            "com.apple.security.application-groups": [GROUP],
            "get-task-allow": False,
        }
        if apple_sign_in:
            entitlements["com.apple.developer.applesignin"] = ["Default"]
        return {
            "Name": "LaterBox App Store",
            "ExpirationDate": datetime.datetime(2027, 1, 1),
            "TeamIdentifier": [TEAM],
            "Entitlements": entitlements,
        }

    def test_main_app_requires_apple_sign_in(self):
        with self.assertRaisesRegex(ValueError, "APPLE_PROVISIONING_PROFILE_BASE64"):
            validate(self.profile(TARGETS["main"]))
        self.assertEqual(validate(self.profile(TARGETS["main"], apple_sign_in=True)), "LaterBox App Store")

    def test_extensions_do_not_require_apple_sign_in(self):
        for bundle in (TARGETS["share"], TARGETS["widgets"]):
            self.assertEqual(validate(self.profile(bundle)), "LaterBox App Store")


if __name__ == "__main__":
    unittest.main()
