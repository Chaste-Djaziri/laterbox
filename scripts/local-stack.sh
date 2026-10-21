#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_DIR="$ROOT_DIR/dev/local"
COMPOSE_FILE="$LOCAL_DIR/compose.yml"
COMPOSE_ENV="$LOCAL_DIR/.env"
FUNCTION_ENV="$ROOT_DIR/supabase/functions/.env"
WEB_ENV="$ROOT_DIR/laterbox-web/.env.local"
IOS_SCHEME_DIR="$ROOT_DIR/laterbox-ios/laterbox-ios.xcodeproj/xcshareddata/xcschemes"
IOS_LOCAL_SCHEME="$IOS_SCHEME_DIR/LaterBoxLocal.xcscheme"
ACTION="${1:-start}"

fail() { printf 'local-stack: %s\n' "$*" >&2; exit 1; }

require_command() { command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"; }

is_private_ipv4() {
  [[ "$1" =~ ^10\. ]] || [[ "$1" =~ ^192\.168\. ]] || [[ "$1" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]
}

detect_lan_host() {
  if [[ -n "${LATERBOX_LOCAL_HOST:-}" ]]; then
    printf '%s' "$LATERBOX_LOCAL_HOST"
    return
  fi

  local candidate=""
  if command -v ipconfig >/dev/null 2>&1; then
    for interface in en0 en1; do
      candidate="$(ipconfig getifaddr "$interface" 2>/dev/null || true)"
      if is_private_ipv4 "$candidate"; then printf '%s' "$candidate"; return; fi
    done
  fi
  if command -v ip >/dev/null 2>&1; then
    candidate="$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}')"
    if is_private_ipv4 "$candidate"; then printf '%s' "$candidate"; return; fi
  fi
  fail 'Could not detect a private LAN IPv4 address. Set LATERBOX_LOCAL_HOST explicitly.'
}

status_value() {
  local name="$1" raw value
  raw="$(npx supabase --workdir "$ROOT_DIR" status -o env)"
  value="$(printf '%s\n' "$raw" | sed -n "s/^${name}=//p" | tail -n 1)"
  value="${value#\"}"
  value="${value%\"}"
  [[ -n "$value" ]] || fail "Supabase status did not provide $name"
  printf '%s' "$value"
}

assert_local_value() {
  local value="$1" label="$2"
  [[ "$value" != *supabase.co* && "$value" != *cloudflarestorage.com* && "$value" != *r2.cloudflarestorage.com* ]] || fail "$label points at a hosted service"
}

write_file() {
  local target="$1"
  umask 077
  cat >"$target"
  chmod 600 "$target"
}

update_android_property() {
  local key="$1" value="$2" properties="$ROOT_DIR/laterbox-android/local.properties" temporary
  temporary="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    index($0, key "=") == 1 { print key "=" value; updated = 1; next }
    { print }
    END { if (!updated) print key "=" value }
  ' "$properties" >"$temporary"
  mv "$temporary" "$properties"
}

write_ios_scheme() {
  local host="$1" anon_key="$2" source="$IOS_SCHEME_DIR/laterbox-ios.xcscheme"
  mkdir -p "$IOS_SCHEME_DIR"
  awk -v supabase_url="http://${host}:54321" -v anon_key="$anon_key" -v web_url="http://${host}:3000" '
    /allowLocationSimulation = "YES">/ {
      print
      print "      <EnvironmentVariables>"
      print "         <EnvironmentVariable key = \"LATERBOX_SUPABASE_URL\" value = \"" supabase_url "\" isEnabled = \"YES\"/>"
      print "         <EnvironmentVariable key = \"LATERBOX_SUPABASE_ANON_KEY\" value = \"" anon_key "\" isEnabled = \"YES\"/>"
      print "         <EnvironmentVariable key = \"LATERBOX_WEB_URL\" value = \"" web_url "\" isEnabled = \"YES\"/>"
      print "         <EnvironmentVariable key = \"LATERBOX_BILLING_URL\" value = \"" web_url "\" isEnabled = \"YES\"/>"
      print "      </EnvironmentVariables>"
      next
    }
    { print }
  ' "$source" >"$IOS_LOCAL_SCHEME"
}

generate_runtime_config() {
  local host="$1" anon_key service_key api_url minio_user minio_password minio_bucket
  api_url="http://${host}:54321"
  anon_key="$(status_value ANON_KEY)"
  service_key="$(status_value SERVICE_ROLE_KEY)"
  minio_user="$(sed -n 's/^MINIO_ROOT_USER=//p' "$COMPOSE_ENV" | tail -n 1)"
  minio_password="$(sed -n 's/^MINIO_ROOT_PASSWORD=//p' "$COMPOSE_ENV" | tail -n 1)"
  minio_bucket="$(sed -n 's/^MINIO_BUCKET=//p' "$COMPOSE_ENV" | tail -n 1)"
  assert_local_value "$api_url" 'Supabase API URL'
  assert_local_value "http://${host}:9000" 'MinIO endpoint'
  [[ -n "$minio_user" && -n "$minio_password" && -n "$minio_bucket" ]] || fail 'MinIO local environment is incomplete'

  write_file "$WEB_ENV" <<EOF
NEXT_PUBLIC_SUPABASE_URL=$api_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=$anon_key
SUPABASE_SERVICE_ROLE_KEY=$service_key
EOF
  write_file "$FUNCTION_ENV" <<EOF
SUPABASE_URL=$api_url
SUPABASE_ANON_KEY=$anon_key
SUPABASE_SERVICE_ROLE_KEY=$service_key
R2_ENDPOINT=http://${host}:9000
R2_REGION=us-east-1
R2_ACCESS_KEY_ID=$minio_user
R2_SECRET_ACCESS_KEY=$minio_password
R2_BUCKET=$minio_bucket
R2_SIGNED_URL_TTL_SECONDS=900
EOF

  local android_properties="$ROOT_DIR/laterbox-android/local.properties"
  [[ -f "$android_properties" ]] || cp "$ROOT_DIR/laterbox-android/local.properties.example" "$android_properties"
  update_android_property SUPABASE_URL "$api_url"
  update_android_property SUPABASE_KEY "$anon_key"
  update_android_property SUPABASE_ANON_KEY "$anon_key"
  update_android_property WEB_BASE_URL "http://${host}:3000"
  update_android_property LATERBOX_WEB_URL "http://${host}:3000"
  write_ios_scheme "$host" "$anon_key"
}

start_stack() {
  require_command docker
  require_command npx
  [[ -f "$COMPOSE_ENV" ]] || { cp "$LOCAL_DIR/.env.example" "$COMPOSE_ENV"; chmod 600 "$COMPOSE_ENV"; }
  local host
  host="$(detect_lan_host)"
  is_private_ipv4 "$host" || fail 'LATERBOX_LOCAL_HOST must be a private IPv4 address'
  docker compose --env-file "$COMPOSE_ENV" -f "$COMPOSE_FILE" up -d --wait minio
  docker compose --env-file "$COMPOSE_ENV" -f "$COMPOSE_FILE" run --build --rm minio-bootstrap
  npx supabase --workdir "$ROOT_DIR" start
  generate_runtime_config "$host"
  printf 'Local LaterBox services are ready on %s. Mailpit: http://%s:54324  MinIO: http://%s:9001\n' "$host" "$host" "$host"
  printf 'Run scripts/local-stack.sh functions in a second terminal before testing Edge Functions.\n'
}

case "$ACTION" in
  start) start_stack ;;
  reset)
    start_stack
    npx supabase --workdir "$ROOT_DIR" db reset
    ;;
  functions)
    [[ -f "$FUNCTION_ENV" ]] || fail 'Run scripts/local-stack.sh start first'
    exec npx supabase --workdir "$ROOT_DIR" functions serve --env-file "$FUNCTION_ENV"
    ;;
  stop)
    npx supabase --workdir "$ROOT_DIR" stop
    docker compose --env-file "$COMPOSE_ENV" -f "$COMPOSE_FILE" down
    ;;
  *) fail 'Usage: scripts/local-stack.sh {start|reset|functions|stop}' ;;
esac
