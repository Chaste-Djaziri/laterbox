import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / 'apple-review-metadata.py'
spec = importlib.util.spec_from_file_location('apple_review_metadata', path)
metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metadata)


class ReviewMetadataTests(unittest.TestCase):
    def test_addition_preserves_description_and_is_idempotent(self):
        original = 'Save your links.\nUse an optional account for cloud access.'
        updated = metadata.description_with_eula(original)
        self.assertTrue(updated.startswith(original))
        self.assertIn(metadata.EULA, updated)
        self.assertEqual(updated, metadata.description_with_eula(updated))

    def test_existing_eula_is_not_rewritten(self):
        original = 'Custom localized heading: ' + metadata.EULA + '\nMore information.'
        self.assertEqual(original, metadata.description_with_eula(original))

    def test_full_description_requires_editing_instead_of_truncation(self):
        with self.assertRaises(ValueError):
            metadata.description_with_eula('a' * 4000)


if __name__ == '__main__':
    unittest.main()
