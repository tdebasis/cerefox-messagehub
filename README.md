# cerefox-messagehub

A small, standalone **cerefox extension** that adds cross-conclave messaging on
top of a stock [cerefox](https://github.com/fstamatelopoulos/cerefox) install —
**no fork required**.

It is a single Supabase **edge function** (`message-hub-mcp`, an MCP-over-HTTP
server) backed by one **table** (`hub_messages`). It has **zero coupling** to
cerefox's core schema, RPCs, or functions, so it deploys *alongside* stock
cerefox and is unaffected by cerefox version upgrades.

> Why an extension and not a fork? Our addition is ~360 lines + one table.
> Forking the whole (TypeScript) cerefox codebase would mean re-reconciling a
> full rewrite on every upstream release for the sake of those few files. As a
> standalone extension we install stock cerefox from its npm binary and deploy
> this on top — exactly the "you can deploy on top of that" path.

## What it provides

An MCP server exposing four tools against `hub_messages`:

| Tool | Purpose |
|------|---------|
| `hub_send` | Send a message to another conclave/agent |
| `hub_poll` | Poll for unread messages addressed to a conclave |
| `hub_search` | Search message history (read + unread) |
| `hub_mark_read` | Mark a message received/processed |

Plus a self-describing `GET /version` endpoint.

## Layout

```
supabase/functions/message-hub-mcp/index.ts   # the edge function (self-contained)
migrations/0001_hub_messages.sql              # table + RLS (idempotent)
deploy.sh                                     # deploy function + apply migration
```

## Deploy (on top of an existing cerefox project)

```bash
CEREFOX_PROJECT_REF=<your-project-ref> \
CEREFOX_DATABASE_URL=<direct-postgres-url> \
  ./deploy.sh
# verify
curl -s https://<project-ref>.supabase.co/functions/v1/message-hub-mcp/version
```

The function uses Supabase's auto-injected `SUPABASE_URL` +
`SUPABASE_SERVICE_ROLE_KEY` — no extra secrets to configure.

## Security

`hub_messages` has **RLS enabled with no permissive policies**: direct
anon/authenticated PostgREST access is denied, while the edge function's
service-role key bypasses RLS. This keeps cross-conclave message bodies
unreadable via the public anon key.

## Client config (MCP)

```json
{
  "mcpServers": {
    "message-hub": {
      "command": "npx",
      "args": ["mcp-remote",
        "https://<project-ref>.supabase.co/functions/v1/message-hub-mcp",
        "--header", "Authorization: Bearer <anon-key>"]
    }
  }
}
```

## Provenance

Originally developed as edge-function additions on a cerefox fork
(`tdebasis/cerefox`); extracted into this standalone extension so the fork can
be retired. Compatible with cerefox v0.9.x.
