#!/usr/bin/env bash
# The delivery "formula": verify, then package. Produces a Unity drop-in zip ONLY
# if the scripts compile and the logic tests pass — so you never receive an
# unverified build. Output: quahog_unity_drop.zip (extract into your Unity project
# root; files land under Assets/...).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
UNITY="$ROOT/QUAHOG_Unity"
OUT="$ROOT/quahog_unity_drop.zip"

echo "########## 1/3  compile-check ##########"
"$DIR/compile-check.sh"

echo "########## 2/3  logic tests ##########"
"$DIR/run-tests.sh" | grep -vE '^\[(Log|Warn|Error)\]' | tail -3

echo "########## 3/3  package ##########"
rm -f "$OUT"
cd "$UNITY"
find Assets/Scripts -name '*.cs' -print0 | xargs -0 zip -q "$OUT"
find Assets/Resources -type f \( -name '*.json' -o -name '*.txt' -o -name '*.bytes' \) -print0 \
  | xargs -0 -r zip -q "$OUT"
echo "Packaged -> $OUT"
unzip -l "$OUT"
