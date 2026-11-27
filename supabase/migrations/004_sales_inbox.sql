create table public.sales_channels (
 phone_number_id text primary key, org_id uuid not null references public.organizations on delete cascade, enabled boolean not null default false
);
create table public.sales_messages (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.organizations on delete cascade,
 phone_number_id text not null references public.sales_channels, provider_id text not null unique,
 contact_ref text not null, body text not null check(length(body)<=4096), received_at timestamptz not null,
 status text not null default 'pending' check(status in ('pending','answered')),
 triage_status text not null default 'queued' check(triage_status in ('queued','ready','failed')),
 category text check(category in ('sales','order','delivery','support','other')), priority text check(priority in ('low','normal','high')),
 suggested_reply text, answered_at timestamptz, outbound_id text
);
create index sales_messages_org_status on public.sales_messages(org_id,status,received_at desc);
alter table public.sales_channels enable row level security;
alter table public.sales_messages enable row level security;
revoke all on public.sales_channels,public.sales_messages from public,anon,authenticated;
grant select,insert,update on public.sales_channels,public.sales_messages to service_role;
grant select on public.sales_messages to authenticated;
create policy sales_member_read on public.sales_messages for select to authenticated using (
 (select auth.jwt()->>'aal')='aal2' and exists(select 1 from public.memberships m where m.org_id=sales_messages.org_id and m.user_id=(select auth.uid()))
);
-- Membership access stays private: use narrowly scoped read RPC instead of the table policy.
revoke select on public.sales_messages from authenticated;
drop policy sales_member_read on public.sales_messages;
create function public.sales_inbox(org uuid) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if coalesce(auth.jwt()->>'aal','') <> 'aal2' or not exists(select 1 from public.memberships where org_id=org and user_id=auth.uid()) then raise exception 'Access denied' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(m) order by received_at desc) from (select id,contact_ref,body,received_at,status,triage_status,category,priority,suggested_reply,answered_at from public.sales_messages where org_id=org order by received_at desc limit 200) m),'[]'::jsonb);
end $$;
revoke all on function public.sales_inbox(uuid) from public,anon;
grant execute on function public.sales_inbox(uuid) to authenticated;
