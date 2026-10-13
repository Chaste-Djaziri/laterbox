"""Inspect or apply the prepared subscription review metadata to LaterBox only."""
import argparse
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.request
import jwt

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'laterbox-ios' / 'ci'))
from app_store import BASE, existing_app, records, request, version

EULA = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED', 'DEVELOPER_REJECTED'}


def description_with_eula(description):
    description = description or ''
    if EULA in description:
        return description
    result = description.rstrip() + '\n\nTerms of Use (EULA): ' + EULA
    if len(result) > 4000:
        raise ValueError('EULA addition exceeds the description limit; shorten this localization first.')
    return result


def patch(resource, identifier, attributes):
    if resource not in {'appStoreVersionLocalizations', 'appStoreReviewDetails'}:
        raise ValueError('Unexpected metadata resource')
    now = int(time.time())
    token = jwt.encode({'iss': os.environ['APP_STORE_CONNECT_ISSUER_ID'], 'iat': now,
                        'exp': now + 600, 'aud': 'appstoreconnect-v1'},
                       Path(os.environ['ASC_KEY_PATH']).read_text(), algorithm='ES256',
                       headers={'kid': os.environ['APP_STORE_CONNECT_KEY_ID']})
    payload = {'data': {'type': resource, 'id': identifier, 'attributes': attributes}}
    req = urllib.request.Request(f'{BASE}/v1/{resource}/{identifier}',
                                 data=json.dumps(payload).encode(), method='PATCH',
                                 headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.load(response)


def prepared_review_notes():
    text = (ROOT / 'docs' / 'apple-review-2026-10-12.md').read_text()
    section = text.split('## Suggested App Review Notes', 1)[1]
    return section.split('```text', 1)[1].split('```', 1)[0].strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    app = existing_app()
    versions = records(f'/v1/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=200')
    editable = [v for v in versions if (v['attributes'].get('appStoreState') or v['attributes'].get('appVersionState')) in EDITABLE]
    if not editable:
        raise RuntimeError('No editable iOS version; no metadata changed.')
    current = max(editable, key=lambda v: version(v['attributes']['versionString']))
    localizations = records(f'/v1/appStoreVersions/{current["id"]}/appStoreVersionLocalizations?limit=200')
    # Prepare every description before modifying any localization.
    changes = [(loc, description_with_eula(loc['attributes'].get('description'))) for loc in localizations]
    print('Editable iOS version:', current['attributes']['versionString'])
    for loc, description in changes:
        print('Description:', loc['attributes']['locale'], 'EULA present' if EULA in (loc['attributes'].get('description') or '') else 'EULA addition prepared')
        if args.apply and description != loc['attributes'].get('description'):
            patch('appStoreVersionLocalizations', loc['id'], {'description': description})
    detail = request(f'/v1/appStoreVersions/{current["id"]}/appStoreReviewDetail')['data']
    if args.apply:
        patch('appStoreReviewDetails', detail['id'], {'signInRequired': False, 'notes': prepared_review_notes()})
    print('Review notes:', 'updated; sign-in optional' if args.apply else 'prepared; sign-in will be optional')
    # Read all shared privacy localizations without changing live app metadata.
    for info in records(f'/v1/apps/{app}/appInfos?limit=200'):
        for loc in records(f'/v1/appInfos/{info["id"]}/appInfoLocalizations?limit=200'):
            url = loc['attributes'].get('privacyPolicyUrl')
            if not url:
                raise RuntimeError('Privacy Policy URL missing for ' + loc['attributes']['locale'])
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=30) as response:
                if response.status != 200:
                    raise RuntimeError('Privacy Policy URL unavailable')
            print('Privacy Policy URL working:', loc['attributes']['locale'])
    if args.apply:
        for loc, _ in changes:
            saved = request(f'/v1/appStoreVersionLocalizations/{loc["id"]}')['data']
            if EULA not in (saved['attributes'].get('description') or ''):
                raise RuntimeError('EULA metadata persistence was not confirmed')
        saved = request(f'/v1/appStoreReviewDetails/{detail["id"]}')['data']
        if saved['attributes'].get('signInRequired') or saved['attributes'].get('notes') != prepared_review_notes():
            raise RuntimeError('Review notes persistence was not confirmed')
        print('Subscription review metadata saved and read back. No build submitted.')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'App Store Connect metadata HTTP {error.code}; no credential or reviewer data logged.') from None
