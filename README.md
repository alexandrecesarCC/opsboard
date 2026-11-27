# Opsboard — connected workspace candidate

This branch replaces the seeded browser workspace with a real Supabase Auth and PostgreSQL RPC adapter. The interface uses the Forest / Lime design system. No demo accounts or sample records are created.

## Setup

1. Create a Supabase project and apply `supabase/migrations/001_workspace.sql` and then `002_team.sql` to a new database.
2. Configure the project URL and public anon key in `src/config.js`. Never include a service-role key.
3. Configure email confirmation in Supabase Auth.
4. Serve the repository over HTTPS (or localhost for development).

The sign-in screen intentionally prevents submission until configured. Sessions use tab-scoped sessionStorage with renewal and server validation on reload. This is interim browser-token storage, not an HttpOnly-cookie design. Organization creation and owner-scoped project/task operations are implemented through transactional RPCs. Direct table access is revoked; organization membership is checked in each RPC. Email-bound invitations, acceptance and revocation are implemented. Invitations appear in the verified recipient's account; outbound email delivery is not implemented. Members remain read-only. Password reset and assignment-based writes are pending.

## Quality gate

Candidate only. SQL migrations, remote auth, browser flows, tenant isolation and deployment require integration testing before merging. The original local demonstration is preserved on main. The existing domain tests remain useful but do not establish backend correctness.

See docs/responsive-spec.md. Remote integration and browser testing remain mandatory.

## Release gate
See docs/mvp-gate.md. The candidate is not approved for production until live tests pass.

## Deployment
Vercel executes `npm run build`, which checks JavaScript syntax and runs unit tests before copying application assets to `dist`. Documentation, migrations and legacy seed storage are not shipped in the deployment output. Preview remains separate from production. Browser and live authentication tests remain release requirements.

Guest demo uses isolated in-memory sample data. Paid registration is closed in the UI; payment enforcement and email activation are pending. See docs/product-scope.md.

See docs/auth-security.md for staged mandatory MFA and release constraints.
