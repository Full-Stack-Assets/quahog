#!/usr/bin/env bash
# Idempotently install the .NET SDK so Unity C# can be compiled/checked in this
# (ephemeral) sandbox. Safe to run repeatedly; exits fast if dotnet is present.
set -euo pipefail

if command -v dotnet >/dev/null 2>&1; then
  echo "dotnet $(dotnet --version) already installed."
  exit 0
fi

echo "Installing .NET SDK 8.0 (Roslyn / csc)…"
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
export DEBIAN_FRONTEND=noninteractive

# Some images ship broken third-party PPAs (deadsnakes / ondrej-php) whose
# signatures fail `apt-get update`. Move them aside so the main Ubuntu repo
# (which carries dotnet-sdk-8.0) can refresh.
mkdir -p /tmp/disabled-ppas 2>/dev/null || true
for f in /etc/apt/sources.list.d/*deadsnakes* /etc/apt/sources.list.d/*ondrej* /etc/apt/sources.list.d/*php*; do
  [ -e "$f" ] && $SUDO mv "$f" /tmp/disabled-ppas/ 2>/dev/null || true
done

$SUDO apt-get update -qq || true
$SUDO apt-get install -y --no-install-recommends dotnet-sdk-8.0

echo "Installed dotnet $(dotnet --version)."
