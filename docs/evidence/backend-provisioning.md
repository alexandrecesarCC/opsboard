# Development backend provisioning

Dedicated Supabase project: opsboard (São Paulo). Quoted incremental monthly project cost: USD 0. Workspace and team migrations applied successfully. Database catalog inspection confirmed RLS enabled on all six application tables, no direct SELECT permission for anon/authenticated, and anonymous EXECUTE denied on all nine workspace RPCs. Authenticated EXECUTE is intentional but requires cross-tenant and role tests before production.

Security advisor: six informational findings for RLS without policies (direct table access intentionally denied); nine warnings for authenticated SECURITY DEFINER RPCs. These remain a release gate; do not interpret as a clean security audit. Auth email delivery, actual account login, session lifecycle and browser tests not yet verified. No service-role credentials committed.
