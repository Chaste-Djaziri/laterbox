"""Reject release bundles without optimization or below Play's 25% threshold."""
import json
from pathlib import Path
import sys
import zipfile


def verify(bundle):
    with zipfile.ZipFile(bundle) as archive:
        metadata = json.loads(archive.read('BUNDLE-METADATA/com.android.tools/r8.json'))
        options = metadata['options']
        for flag in ('isObfuscationEnabled', 'isOptimizationsEnabled', 'isShrinkingEnabled'):
            if options.get(flag) is not True:
                raise ValueError(f'R8 {flag} must be enabled')
        if metadata.get('resourceOptimization', {}).get('isOptimizedShrinkingEnabled') is not True:
            raise ValueError('Optimized resource shrinking must be enabled')
        for metric in ('Obfuscation', 'Optimization', 'Shrinking'):
            protected = metadata['stats']['no' + metric + 'Percentage']
            if not isinstance(protected, (int, float)) or not 0 <= protected <= 100:
                raise ValueError(f'Invalid {metric} percentage')
            score = 100 - protected
            print(f'{metric}: {score:.2f}%')
            if score < 25:
                raise ValueError(f'{metric} {score:.2f}% is below the 25% threshold')
        if 'BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map' not in archive.namelist():
            raise ValueError('Bundle is missing the crash deobfuscation mapping')
        dex_size = sum(entry.file_size for entry in archive.infolist() if entry.filename.endswith('.dex'))
        print(f'Uncompressed DEX: {dex_size / 1_000_000:.2f} MB; R8 {metadata["version"]}')


if __name__ == '__main__':
    verify(Path(sys.argv[1]))
