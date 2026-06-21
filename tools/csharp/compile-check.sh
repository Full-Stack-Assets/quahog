#!/usr/bin/env bash
# Headlessly type-check every Unity gameplay script against the local UnityEngine
# shim. Exit code is non-zero if anything fails to compile.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$DIR/setup.sh"

echo "=== Compile-checking QUAHOG gameplay scripts (UnityEngine shim) ==="
dotnet build "$DIR/CompileCheck.csproj" -v q -nologo
echo "=== Compile check OK ==="
