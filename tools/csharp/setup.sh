#!/usr/bin/env bash
# Idempotently install the .NET SDK so Unity C# can be compiled/checked in this
# (ephemeral) sandbox. Safe to run repeatedly; exits fast if dotnet is present.
#
# Two install paths, tried in order, so the gate works across environments with
# different egress allowlists:
#   1. apt   — fast when the Ubuntu OS repos (archive/security.ubuntu.com) are allowed.
#   2. Microsoft's dotnet-install.sh — pulls the SDK straight from the .NET CDN
#      (dot.net / builds.dotnet.microsoft.com) when apt is blocked or broken.
# Whichever wins, `dotnet` is left on PATH (symlinked into /usr/local/bin) so the
# compile-check / test scripts that call `dotnet` by name find it.
set -uo pipefail

DOTNET_CHANNEL="8.0"

if command -v dotnet >/dev/null 2>&1; then
  echo "dotnet $(dotnet --version) already installed."
  exit 0
fi

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
export DEBIAN_FRONTEND=noninteractive

# --- Path 1: apt (Ubuntu repos carry dotnet-sdk-8.0) -------------------------
try_apt() {
  echo "Trying apt install of .NET SDK ${DOTNET_CHANNEL}…"

  # Some images ship broken third-party PPAs (deadsnakes / ondrej-php) whose
  # signatures fail `apt-get update`. Move them aside so the main Ubuntu repo
  # (which carries dotnet-sdk-8.0) can refresh.
  mkdir -p /tmp/disabled-ppas 2>/dev/null || true
  for f in /etc/apt/sources.list.d/*deadsnakes* /etc/apt/sources.list.d/*ondrej* /etc/apt/sources.list.d/*php*; do
    [ -e "$f" ] && $SUDO mv "$f" /tmp/disabled-ppas/ 2>/dev/null || true
  done

  $SUDO apt-get update -qq || true
  $SUDO apt-get install -y --no-install-recommends "dotnet-sdk-${DOTNET_CHANNEL}"
}

# --- Path 2: Microsoft dotnet-install.sh (CDN) ------------------------------
try_cdn() {
  echo "apt path unavailable; falling back to Microsoft dotnet-install.sh (CDN)…"
  local script="/tmp/dotnet-install.sh"
  # The agent proxy's CA is already trusted system-wide, so plain curl works
  # once the host is allowed by the egress policy.
  if ! curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$script"; then
    echo "Could not download dotnet-install.sh (is dot.net allowed by egress?)." >&2
    return 1
  fi
  chmod +x "$script"

  # Prefer a system prefix (root) so the symlink below lands on PATH; else use $HOME.
  local install_dir="/usr/local/dotnet"
  if [ -n "$SUDO" ] || [ ! -w "/usr/local" ]; then install_dir="$HOME/.dotnet"; fi

  if ! "$script" --channel "$DOTNET_CHANNEL" --install-dir "$install_dir" --no-path; then
    echo "dotnet-install.sh failed (is builds.dotnet.microsoft.com allowed?)." >&2
    return 1
  fi

  export DOTNET_ROOT="$install_dir"
  # Put `dotnet` on PATH for the scripts that invoke it by name.
  if [ -w /usr/local/bin ] || [ -n "$SUDO" ]; then
    $SUDO ln -sf "$install_dir/dotnet" /usr/local/bin/dotnet
  else
    mkdir -p "$HOME/.local/bin" && ln -sf "$install_dir/dotnet" "$HOME/.local/bin/dotnet"
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

echo "Installing .NET SDK ${DOTNET_CHANNEL} (Roslyn / csc)…"
if try_apt && command -v dotnet >/dev/null 2>&1; then
  echo "Installed dotnet $(dotnet --version) via apt."
elif try_cdn && command -v dotnet >/dev/null 2>&1; then
  echo "Installed dotnet $(dotnet --version) via Microsoft CDN."
else
  echo "ERROR: could not install the .NET SDK by apt or CDN." >&2
  echo "  Allow one of these host sets in the environment's egress policy and retry:" >&2
  echo "    - apt: archive.ubuntu.com, security.ubuntu.com" >&2
  echo "    - CDN: dot.net, builds.dotnet.microsoft.com" >&2
  exit 1
fi
