#!/usr/bin/env bash
# Scaffold a Flutter app that compiles and can send 0.001 NEAR on testnet.
set -euo pipefail

NAME="${1:-my_near_pay}"
if [[ ! "$NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Project name must be a Dart package name (e.g. my_near_pay)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Install Flutter first: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$ROOT/templates/pay_testnet/lib/main.dart"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Missing template at $TEMPLATE" >&2
  exit 1
fi

if [[ -e "$NAME" ]]; then
  echo "Refusing to overwrite ./$NAME" >&2
  exit 1
fi

flutter create --org org.near --project-name "$NAME" --platforms android,ios "$NAME"
(
  cd "$NAME"
  flutter pub add near_dart
  cp "$TEMPLATE" lib/main.dart
)

python3 - "$NAME" <<'PY'
import pathlib
import sys

name = sys.argv[1]
root = pathlib.Path(name)

manifest = root / "android/app/src/main/AndroidManifest.xml"
text = manifest.read_text()
needle = """            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>"""
insert = needle + """
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="nearpay"/>
            </intent-filter>"""
if needle in text and "android:scheme=\"nearpay\"" not in text:
    manifest.write_text(text.replace(needle, insert, 1))

plist = root / "ios/Runner/Info.plist"
plist_text = plist.read_text()
url_types = """	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>nearpay</string>
			</array>
		</dict>
	</array>
"""
if "CFBundleURLTypes" not in plist_text:
    marker = "</dict>\n</plist>"
    idx = plist_text.rfind(marker)
    if idx == -1:
        raise SystemExit(f"Could not patch {plist}")
    plist.write_text(plist_text[:idx] + url_types + plist_text[idx:])
PY

cat <<EOF
Created ./$NAME

Next:
  1. near create-account <you>.testnet --useFaucet --networkId testnet
  2. near account export-account <you>.testnet
  3. cd $NAME && flutter run
  4. Paste the testnet account + ed25519 key, tap Send on testnet.

Never paste a mainnet key. README: templates/pay_testnet/README.md
EOF
