#!/usr/bin/env bash
# Package Mount Hope when Unreal Engine and editor content are available.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
UPROJECT="${PROJECT_ROOT}/MountHope.uproject"

if [[ -z "${UE_ROOT:-}" ]]; then
  echo "ERROR: UE_ROOT is not set." >&2
  exit 1
fi

PLATFORM="${PLATFORM:-Win64}"
CONFIGURATION="${CONFIGURATION:-Development}"
ARCHIVE_DIR="${ARCHIVE_DIR:-${PROJECT_ROOT}/Packaged/${PLATFORM}}"

RUNUAT="${UE_ROOT}/Engine/Build/BatchFiles/RunUAT.sh"
if [[ ! -x "${RUNUAT}" ]]; then
  echo "ERROR: RunUAT.sh not found at ${RUNUAT}" >&2
  exit 1
fi

mkdir -p "${ARCHIVE_DIR}"

echo "Packaging MountHope for ${PLATFORM} (${CONFIGURATION})..."
"${RUNUAT}" BuildCookRun \
  -project="${UPROJECT}" \
  -noP4 \
  -platform="${PLATFORM}" \
  -clientconfig="${CONFIGURATION}" \
  -serverconfig="${CONFIGURATION}" \
  -cook \
  -build \
  -stage \
  -pak \
  -archive \
  -archivedirectory="${ARCHIVE_DIR}"

echo "Package archived to: ${ARCHIVE_DIR}"
