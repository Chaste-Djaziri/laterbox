import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from verify_r8 import verify


class R8BundleTests(unittest.TestCase):
    def check_bundle(self, protected=2, enabled=True, mapping=True):
        with tempfile.TemporaryDirectory() as directory:
            bundle = Path(directory) / 'test.aab'
            with zipfile.ZipFile(bundle, 'w') as archive:
                archive.writestr('BUNDLE-METADATA/com.android.tools/r8.json', json.dumps({
                    'version': '9.0.32', 'options': {key: enabled for key in
                        ['isObfuscationEnabled', 'isOptimizationsEnabled', 'isShrinkingEnabled']},
                    'resourceOptimization': {'isOptimizedShrinkingEnabled': True},
                    'stats': {f'no{key}Percentage': protected for key in ['Obfuscation', 'Optimization', 'Shrinking']}}))
                if mapping:
                    archive.writestr('BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map', 'mapping')
                archive.writestr('base/dex/classes.dex', b'dex')
            with contextlib.redirect_stdout(io.StringIO()):
                verify(bundle)

    def test_accepts_optimized_bundle(self):
        self.check_bundle()

    def test_rejects_disabled_optimization(self):
        with self.assertRaisesRegex(ValueError, 'must be enabled'):
            self.check_bundle(enabled=False)

    def test_rejects_below_play_threshold(self):
        with self.assertRaisesRegex(ValueError, 'below the 25% threshold'):
            self.check_bundle(protected=76)

    def test_rejects_missing_crash_mapping(self):
        with self.assertRaisesRegex(ValueError, 'missing the crash'):
            self.check_bundle(mapping=False)

    def test_rejects_invalid_percentage(self):
        with self.assertRaisesRegex(ValueError, 'Invalid'):
            self.check_bundle(protected=101)


if __name__ == '__main__':
    unittest.main()
