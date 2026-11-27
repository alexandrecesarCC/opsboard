-- Membership invitations are bound to the verified email of an authenticated account.
create table public.workspace_invitations (
 id uuid primary key default gen_random_uuid(),
 org_id uuid not null references public.organizations on delete cascade,
 email text not null check (length(email) between 3 and 254),
 role text not null check (role in ('member','viewer')),
 created_by uuid not null references auth.users,
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default (now()+interval '7 days'),
 accepted_at timestamptz,
 revoked_at timestamptz
);
alter table public.workspace_invitations enable row level security;
revoke all on public.workspace_invitations from anon,authenticated;
create unique index workspace_invitation_pending on public.workspace_invitations(org_id,email) where accepted_at is null and revoked_at is null;
create function public.invite_workspace_member(org uuid, invite_email text, invite_role text) returns uuid
language plpgsql security definer set search_path='' as $$
declare normalized text:=lower(trim(invite_email)); invitation_id uuid;
begin
 if not exists(select 1 from public.memberships where org_id=org and user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Access denied'; end if;
 if normalized is null or normalized !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(normalized)>254 or invite_role not in ('member','viewer') then raise exception 'Invalid invitation'; end if;
 update public.workspace_invitations set revoked_at=now() where org_id=org and email=normalized and accepted_at is null and revoked_at is null and expires_at<=now();
 if exists(select 1 from public.memberships m join auth.users u on u.id=m.user_id where m.org_id=org and lower(u.email)=normalized) then raise exception 'Already a member'; end if;
 insert into public.workspace_invitations(org_id,email,role,created_by) values(org,normalized,invite_role,auth.uid()) returning id into invitation_id;
 insert into public.audit_log(org_id,actor,label) values(org,auth.uid(),'Created team invitation');
 return invitation_id;
end $$;
create function public.my_workspace_invitations() returns jsonb
language sql security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'organization',o.name,'role',i.role,'expiresAt',i.expires_at)),'[]'::jsonb)
 from public.workspace_invitations i join public.organizations o on o.id=i.org_id join auth.users u on u.id=auth.uid()
 where u.email_confirmed_at is not null and lower(u.email)=i.email and i.accepted_at is null and i.revoked_at is null and i.expires_at>now()
$$;
create function public.accept_workspace_invitation(invitation uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare item public.workspace_invitations%rowtype;
begin
 select i.* into item from public.workspace_invitations i join auth.users u on u.id=auth.uid()
 where i.id=invitation and u.email_confirmed_at is not null and lower(u.email)=i.email and i.accepted_at is null and i.revoked_at is null and i.expires_at>now() for update of i;
 if not found then raise exception 'Invitation unavailable'; end if;
 insert into public.memberships(org_id,user_id,role) values(item.org_id,auth.uid(),item.role) on conflict do nothing;
 update public.workspace_invitations set accepted_at=now() where id=item.id;
 insert into public.audit_log(org_id,actor,label) values(item.org_id,auth.uid(),'Accepted team invitation');
 return item.org_id;
end $$;
create function public.workspace_team(org uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.memberships where org_id=org and user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Access denied'; end if;
 return jsonb_build_object('members',coalesce((select jsonb_agg(jsonb_build_object('id',m.user_id,'email',u.email,'role',m.role)) from public.memberships m join auth.users u on u.id=m.user_id where m.org_id=org),'[]'::jsonb),'invitations',coalesce((select jsonb_agg(jsonb_build_object('id',id,'email',email,'role',role,'expiresAt',expires_at)) from public.workspace_invitations where org_id=org and accepted_at is null and revoked_at is null and expires_at>now()),'[]'::jsonb));
end $$;
create function public.revoke_workspace_invitation(org uuid, invitation uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.memberships where org_id=org and user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Access denied'; end if;
 update public.workspace_invitations set revoked_at=now() where org_id=org and id=invitation and accepted_at is null and revoked_at is null;
 if not found then raise exception 'Invitation unavailable'; end if;
 insert into public.audit_log(org_id,actor,label) values(org,auth.uid(),'Revoked team invitation');
end $$;
revoke all on function public.invite_workspace_member(uuid,text,text),public.my_workspace_invitations(),public.accept_workspace_invitation(uuid),public.workspace_team(uuid),public.revoke_workspace_invitation(uuid,uuid) from public,anon;
grant execute on function public.invite_workspace_member(uuid,text,text),public.my_workspace_invitations(),public.accept_workspace_invitation(uuid),public.workspace_team(uuid),public.revoke_workspace_invitation(uuid,uuid) to authenticated;
