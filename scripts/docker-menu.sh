#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/container-menu-$(date +%Y%m%d-%H%M%S).log"

ENGINE=""
if command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
elif command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
else
  echo "No container runtime found. Install docker or podman."
  exit 1
fi

log_cmd() {
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[${timestamp}] $*" | tee -a "$LOG_FILE" >&2
}

run_engine() {
  log_cmd "$ENGINE $*"
  "$ENGINE" "$@" 2>&1 | tee -a "$LOG_FILE"
  return "${PIPESTATUS[0]}"
}

log_cmd "Session started (engine: ${ENGINE})"
echo "Command log: ${LOG_FILE}"

suggest_tag() {
  local dockerfile="$1"
  local folder variant rand
  folder="$(basename "$(dirname "$dockerfile")")"
  variant="${dockerfile##*.}"
  rand="$((RANDOM % 9000 + 1000))"
  echo "clone/${folder}-${variant}-${rand}"
}

list_dockerfiles() {
  find images -type f -name 'Dockerfile.*' | sort
}

normalize_mount_path() {
  local raw="$1"
  local normalized
  normalized="${raw//\\//}"

  # Handle Windows drive-style paths like C:/Users/... or C:\Users\...
  if [[ "$normalized" =~ ^[A-Za-z]:/ ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$normalized"
      return
    fi
  fi

  echo "$normalized"
}

build_image() {
  mapfile -t files < <(list_dockerfiles)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No Dockerfiles found under images/."
    return
  fi

  echo
  echo "Select Dockerfile to build:"
  local i=1
  for file in "${files[@]}"; do
    echo "  $i) $file"
    i=$((i + 1))
  done

  read -r -p "Number: " pick
  if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#files[@]} )); then
    echo "Invalid selection."
    return
  fi

  local selected="${files[pick-1]}"
  local default_tag
  default_tag="$(suggest_tag "$selected")"

  read -r -p "Image tag [${default_tag}]: " tag
  tag="${tag:-$default_tag}"

  echo
  echo "Building ${selected} as ${tag}"
  run_engine build -f "$selected" -t "$tag" "$(dirname "$selected")"
  echo "Build completed."
}

run_image() {
  mapfile -t images < <(run_engine images --format '{{.Repository}}:{{.Tag}}' | sort -u)

  if [[ ${#images[@]} -eq 0 ]]; then
    echo "No local images found. Build an image first."
    return
  fi

  echo
  echo "Select image to run:"
  local i=1
  for image in "${images[@]}"; do
    echo "  $i) $image"
    i=$((i + 1))
  done

  read -r -p "Number (or type image directly): " choice
  local selected_image
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#images[@]} )); then
    selected_image="${images[choice-1]}"
  else
    selected_image="$choice"
  fi

  local default_server="rpi-$((RANDOM % 9000 + 1000))"
  read -r -p "Server name / hostname [${default_server}]: " server_name
  server_name="${server_name:-$default_server}"

  read -r -p "Port prefix (10-99): " prefix
  if ! [[ "$prefix" =~ ^[1-9][0-9]$ ]] || (( prefix < 10 || prefix > 99 )); then
    echo "Invalid prefix. Use a number between 10 and 99."
    return
  fi

  read -r -p "Optional host path to mount at /var/media (leave empty to skip): " mount_path
  local -a mount_args=()
  if [[ -n "$mount_path" ]]; then
    local mount_path_normalized
    mount_path_normalized="$(normalize_mount_path "$mount_path")"
    mount_args=(-v "${mount_path_normalized}:/var/media")
  fi

  local p80="${prefix}89"
  local p8080="${prefix}88"
  local p22="${prefix}22"
  local p3306="${prefix}33"

  if run_engine ps -a --format '{{.Names}}' | grep -Fxq "$server_name"; then
    echo "Container name ${server_name} already exists. Choose another name."
    return
  fi

  echo
  echo "Starting container ${server_name} from ${selected_image}"
  echo "Port mapping: ${p80}->80, ${p8080}->8080, ${p22}->22, ${p3306}->3306"
  if [[ ${#mount_args[@]} -gt 0 ]]; then
    echo "Mount: ${mount_args[1]}"
  fi

  run_engine run -d \
    --name "$server_name" \
    --hostname "$server_name" \
    -p "${p80}:80" \
    -p "${p8080}:8080" \
    -p "${p22}:22" \
    -p "${p3306}:3306" \
    "${mount_args[@]}" \
    "$selected_image"

  echo "Container started."
}

while true; do
  echo
  echo "==== Container Menu (${ENGINE}) ===="
  echo "1) Build image"
  echo "2) Run image"
  echo "3) List Dockerfiles"
  echo "0) Exit"
  read -r -p "Choice: " menu

  case "$menu" in
    1) build_image ;;
    2) run_image ;;
    3) list_dockerfiles ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
