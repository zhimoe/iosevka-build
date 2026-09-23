#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly IOSEVKA_DIR="${SCRIPT_DIR}/Iosevka"
readonly BUILD_PLAN_FILE="${SCRIPT_DIR}/private-build-plans.toml"
readonly IMAGE_NAME="${IMAGE_NAME:-iosevka-builder}"
readonly PLAN_NAME="${PLAN_NAME:-Iosevka}"
readonly JOBS="${JOBS:-6}"
readonly DOCKER_WAIT_SECONDS="${DOCKER_WAIT_SECONDS:-120}"
readonly IOSEVKA_REPOSITORY="https://github.com/be5invis/Iosevka.git"

log() {
  printf '[iosevka-build] %s\n' "$*"
}

fail() {
  printf '[iosevka-build] Error: %s\n' "$*" >&2
  exit 1
}

docker_is_ready() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

ensure_docker() {
  if docker_is_ready; then
    log 'Docker is ready.'
    return
  fi

  [[ "$(uname -s)" == 'Darwin' ]] ||
    fail 'Docker is not running. Start Docker and run this script again.'

  command -v open >/dev/null 2>&1 || fail "macOS command 'open' is unavailable."
  open -Ra 'OrbStack' >/dev/null 2>&1 ||
    fail 'Docker is not running and OrbStack is not installed or registered with macOS.'

  if pgrep -x 'OrbStack' >/dev/null 2>&1; then
    log 'OrbStack is running; waiting for Docker...'
  else
    log 'Docker is unavailable; starting OrbStack...'
  fi

  # Calling open is harmless when OrbStack already has a process, and also wakes
  # it when the application is running but its Linux machine is not ready yet.
  open -a 'OrbStack'

  local deadline=$((SECONDS + DOCKER_WAIT_SECONDS))
  while ((SECONDS < deadline)); do
    if docker_is_ready; then
      log 'Docker is ready.'
      return
    fi
    sleep 2
  done

  if ! command -v docker >/dev/null 2>&1; then
    fail "OrbStack started, but the 'docker' command is unavailable. Install OrbStack's command-line tools and retry."
  fi
  fail "OrbStack started, but Docker was not ready within ${DOCKER_WAIT_SECONDS} seconds."
}

prepare_source() {
  if [[ ! -e "${IOSEVKA_DIR}" ]]; then
    command -v git >/dev/null 2>&1 || fail "The 'git' command is required."
    log 'Cloning Iosevka (shallow clone)...'
    git clone --depth 1 "${IOSEVKA_REPOSITORY}" "${IOSEVKA_DIR}"
  elif [[ ! -d "${IOSEVKA_DIR}/.git" || ! -d "${IOSEVKA_DIR}/docker" ]]; then
    fail "${IOSEVKA_DIR} exists but is not an Iosevka Git checkout."
  else
    log 'Using the existing Iosevka checkout.'
  fi
}

prepare_build_plan_mount() {
  [[ -f "${BUILD_PLAN_FILE}" ]] ||
    fail "Build plan not found: ${BUILD_PLAN_FILE}"

  local mount_target="${IOSEVKA_DIR}/private-build-plans.toml"
  if [[ -d "${mount_target}" ]]; then
    # rmdir deliberately fails rather than deleting anything if the directory
    # contains files.
    rmdir "${mount_target}" ||
      fail "${mount_target} is a non-empty directory; move it aside and retry."
  elif [[ -e "${mount_target}" && ! -f "${mount_target}" ]]; then
    fail "${mount_target} exists but is not a regular file."
  fi

  # Docker Desktop/OrbStack needs a file-shaped target inside the /work bind
  # mount. This prevents a missing target from being created as a directory.
  [[ -e "${mount_target}" ]] || touch "${mount_target}"
}

build_image() {
  log "Building Docker image ${IMAGE_NAME}..."
  docker build -t "${IMAGE_NAME}" "${IOSEVKA_DIR}/docker"
}

build_font() {
  local -a docker_args=(run)
  if [[ -t 0 && -t 1 ]]; then
    docker_args+=(-it)
  fi

  docker_args+=(
    --rm
    -v "${IOSEVKA_DIR}:/work"
    -v "${BUILD_PLAN_FILE}:/work/private-build-plans.toml:ro"
    --entrypoint bash
    "${IMAGE_NAME}"
    -lc '[ -d node_modules ] || npm install; npm run build -- "ttf::$1" "--jCmd=$2"'
    _ "${PLAN_NAME}" "${JOBS}"
  )

  log "Building ttf::${PLAN_NAME} with ${JOBS} parallel jobs..."
  docker "${docker_args[@]}"

  log "Build completed. Output: ${IOSEVKA_DIR}/dist"
}

main() {
  [[ "${JOBS}" =~ ^[1-9][0-9]*$ ]] || fail 'JOBS must be a positive integer.'
  [[ "${DOCKER_WAIT_SECONDS}" =~ ^[1-9][0-9]*$ ]] ||
    fail 'DOCKER_WAIT_SECONDS must be a positive integer.'

  ensure_docker
  prepare_source
  prepare_build_plan_mount
  build_image
  build_font
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
