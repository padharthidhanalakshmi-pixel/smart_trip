"""Adds permissions and app names to the platform folders made by `flutter create`.

Run from the project root after `flutter create`. Safe to run more than once.
"""
import pathlib
import re

ANDROID = pathlib.Path('android/app/src/main/AndroidManifest.xml')
IOS = pathlib.Path('ios/Runner/Info.plist')

PERMISSIONS = [
    'android.permission.INTERNET',  # release builds don't include this by default
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
]

QUERY_INTENTS = '''        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="geo" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="text/plain" />
        </intent>'''


def patch_android():
    if not ANDROID.exists():
        print('No Android manifest found; skipping.')
        return
    s = ANDROID.read_text()
    missing = [p for p in PERMISSIONS if p not in s]
    if missing:
        lines = '\n'.join(f'    <uses-permission android:name="{p}" />' for p in missing)
        s = re.sub(r'(\n[ \t]*<application)', '\n' + lines + r'\1', s, count=1)
    if 'android:scheme="geo"' not in s:
        if '<queries>' in s:
            s = s.replace('<queries>', '<queries>\n' + QUERY_INTENTS, 1)
        else:
            s = s.replace('</manifest>', '    <queries>\n' + QUERY_INTENTS + '\n    </queries>\n</manifest>', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="Smart Trip"', s, count=1)
    ANDROID.write_text(s)
    print('Android manifest patched.')


def patch_ios():
    if not IOS.exists():
        print('No iOS Info.plist found; skipping.')
        return
    s = IOS.read_text()
    extra = ''
    if 'NSLocationWhenInUseUsageDescription' not in s:
        extra += ('\t<key>NSLocationWhenInUseUsageDescription</key>\n'
                  '\t<string>Smart Trip uses your location once to fill in your starting point.</string>\n')
    if 'LSApplicationQueriesSchemes' not in s:
        extra += ('\t<key>LSApplicationQueriesSchemes</key>\n'
                  '\t<array>\n\t\t<string>https</string>\n\t\t<string>tel</string>\n\t</array>\n')
    if extra:
        i = s.rfind('</dict>')
        s = s[:i] + extra + s[i:]
    s = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', r'\1Smart Trip\2', s, count=1)
    IOS.write_text(s)
    print('iOS Info.plist patched.')


if __name__ == '__main__':
    patch_android()
    patch_ios()
