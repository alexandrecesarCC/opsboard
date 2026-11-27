# MVP release gate
- [ ] Provision a dedicated Supabase development project; apply migrations 001 and 002 in order.
- [ ] Verify email confirmation, sign-in, reload, token refresh, logout and password reset.
- [ ] Verify empty organization, project/task CRUD, Kanban, calendar, analytics and persisted changes.
- [ ] Use two verified test accounts and two organizations; verify cross-tenant denial, wrong-email invitation denial, expired/revoked invitation denial, viewer write denial and direct table access denial.
- [ ] Verify owner/admin invitation creation and revocation; recipient acceptance; no privilege escalation.
- [ ] Execute npm run check and npm test; run browser flows at every viewport in responsive-spec.md.
- [ ] Configure HTTPS deployment, secrets, backups, monitoring and rollback; inspect production preview before promotion.
No check is marked passed by source inspection alone.
