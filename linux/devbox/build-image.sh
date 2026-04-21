#!/usr/bin/env bash

set -u

CONTAINER_CMD="${CONTAINER_CMD:-docker}"
IMAGE_NAME="${IMAGE_NAME:-devops-ubuntu:24.04}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

runtime() {
  command "$CONTAINER_CMD" "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"
  local default_answer="${2:-no}"
  local answer suffix

  case "$default_answer" in
    yes|y|Y) suffix='[Y/n]' ;;
    no|n|N) suffix='[y/N]' ;;
    *) suffix='[y/n]' ;;
  esac

  while true; do
    printf '%s %s: ' "$prompt" "$suffix" >&2
    IFS= read -r answer
    if [ -z "$answer" ]; then
      answer="$default_answer"
    fi
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) warn 'Please answer yes or no.' ;;
    esac
  done
}

ensure_runtime_available() {
  command_exists "$CONTAINER_CMD" || die "Container runtime not found: $CONTAINER_CMD"
}

image_exists() {
  runtime image inspect "$IMAGE_NAME" >/dev/null 2>&1
}

list_containers_using_image() {
  runtime ps -a --filter "ancestor=${IMAGE_NAME}" --format '{{.Names}}\t{{.Status}}' 2>/dev/null || true
}

remove_existing_image() {
  local containers_using_image

  containers_using_image=$(list_containers_using_image)
  if [ -n "$containers_using_image" ]; then
    warn "Image '${IMAGE_NAME}' is currently used by these containers:"
    printf '%s\n' "$containers_using_image" >&2
    die 'Please stop and remove the containers above before rebuilding this image.'
  fi

  runtime rmi "$IMAGE_NAME" >/dev/null || die "Failed to remove existing image: $IMAGE_NAME"
}

build_image() {
  info "Building image: ${IMAGE_NAME}"
  runtime build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$BUILD_CONTEXT" || die 'Image build failed.'
  info "Image built successfully: ${IMAGE_NAME}"
}

main() {
  ensure_runtime_available
  [ -f "$DOCKERFILE_PATH" ] || die "Dockerfile not found: $DOCKERFILE_PATH"

  if image_exists; then
    info "Image already exists: ${IMAGE_NAME}"
    if confirm "Overwrite existing image '${IMAGE_NAME}'?" 'no'; then
      remove_existing_image
    else
      die 'Build cancelled.'
    fi
  fi

  build_image
}

main "$@"
