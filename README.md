# Opsboard — connected workspace candidate

This branch replaces the seeded browser workspace with a real Supabase Auth and PostgreSQL RPC adapter. The interface uses the Forest / Lime design system. No demo accounts or sample records are created.

## Setup

1. Create a Supabase project and apply `supabase/migrations/001_workspace.sql` to a new database.
2. Configure the project URL and public anon key in `src/config.js`. Never include a service-role key.
3. Configure email confirmation in Supabase Auth.
4. Serve the repository over HTTPS (or localhost for development).

The sign-in screen intentionally prevents submission until configured. Sessions use tab-scoped sessionStorage with renewal and server validation on reload. This is interim browser-token storage, not an HttpOnly-cookie design. Organization creation and owner-scoped project/task operations are implemented through transactional RPCs. Direct table access is revoked; organization membership is checked in each RPC. No team invitation, password reset, or assignment-based member writes yet.

## Quality gate

Candidate only. SQL migrations, remote auth, browser flows, tenant isolation and deployment require integration testing before merging. The original local demonstration is preserved on main. The existing domain tests remain useful but do not establish backend correctness.

See docs/responsive-spec.md. Remote integration and browser testing remain mandatory.
