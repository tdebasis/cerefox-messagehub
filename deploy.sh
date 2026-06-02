#!/usr/bin/env bash
# Deploy the message-hub cerefox extension ON TOP of a stock cerefox install.
#
# Prereqs:
#   - supabase CLI installed + logged in (`supabase login`)
#   - psql installed
#   - The cerefox Supabase project ref + a direct Postgres URL.
#
# Env (or pass inline):
#   CEREFOX_PROJECT_REF   Supabase project ref (e.g. nbjemizeqstvvxtabubu)
#   CEREFOX_DATABASE_URL  Direct Postgres connection string (for the migration)
#
# The edge function reads SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY, which
# Supabase injects into every edge function automatically — no secret config
# needed. Service-role bypasses the RLS enabled by the migration.
#
# Usage:
#   CEREFOX_PROJECT_REF=xxx CEREFOX_DATABASE_URL=postgres://... ./deploy.sh
#   ./deploy.sh --migration-only      # apply the SQL only
#   ./deploy.sh --function-only       # deploy the edge function only

set -euo pipefail
cd "$(dirname "$0")"

DO_FN=1; DO_MIG=1
case "${1:-}" in
  --migration-only) DO_FN=0 ;;
  --function-only)  DO_MIG=0 ;;
  "" ) ;;
  *) echo "Unknown arg: $1"; exit 1 ;;
esac

: "${CEREFOX_PROJECT_REF:?set CEREFOX_PROJECT_REF (Supabase project ref)}"

if [ "$DO_MIG" = 1 ]; then
  : "${CEREFOX_DATABASE_URL:?set CEREFOX_DATABASE_URL (direct Postgres URL) for the migration}"
  echo "→ Applying migration 0001_hub_messages.sql (idempotent)…"
  psql "$CEREFOX_DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/0001_hub_messages.sql
fi

if [ "$DO_FN" = 1 ]; then
  echo "→ Deploying edge function message-hub-mcp to project $CEREFOX_PROJECT_REF…"
  supabase functions deploy message-hub-mcp --project-ref "$CEREFOX_PROJECT_REF"
fi

echo "✓ Done. Verify: curl -s https://$CEREFOX_PROJECT_REF.supabase.co/functions/v1/message-hub-mcp/version"
