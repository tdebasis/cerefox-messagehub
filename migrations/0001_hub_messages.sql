-- Migration 0001: hub_messages — cross-conclave message transport table
--
-- Standalone cerefox extension (NOT part of cerefox's own migration chain).
-- Backs the message-hub-mcp edge function. Apply against the same Supabase
-- project that hosts cerefox.
--
-- Row Level Security: enabled with NO permissive policies. Direct table access
-- via the anon/authenticated roles (PostgREST) is therefore denied; the
-- service-role key used by the message-hub-mcp edge function bypasses RLS and
-- keeps working. This prevents the public anon key (shipped in client .mcp.json)
-- from reading/writing cross-conclave message bodies directly.
--
-- Idempotent: CREATE ... IF NOT EXISTS and ENABLE ROW LEVEL SECURITY are both
-- safe to re-run.

create table if not exists hub_messages (
  id uuid primary key default gen_random_uuid(),
  from_conclave text not null,
  from_agent text not null,
  to_conclave text not null,
  to_agent text not null default 'all',
  subject text not null,
  body text not null,
  created_at timestamptz not null default now(),
  received_at timestamptz,
  received_by text
);

create index if not exists idx_hub_messages_to
  on hub_messages(to_conclave, received_at);

create index if not exists idx_hub_messages_created
  on hub_messages(created_at desc);

-- RLS: deny direct anon/authenticated access; service-role (edge fn) bypasses.
alter table hub_messages enable row level security;
