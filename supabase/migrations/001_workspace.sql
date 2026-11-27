-- Apply to a new Supabase database. No service-role key is used by the client.
create table public.organizations(id uuid primary key default gen_random_uuid(),name text not null check(char_length(trim(name)) between 1 and 100));
create table public.memberships(org_id uuid references public.organizations on delete cascade,user_id uuid references auth.users on delete cascade,role text not null check(role in ('owner','admin','member','viewer')),primary key(org_id,user_id));
create table public.projects(id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations on delete cascade,name text not null check(char_length(trim(name)) between 1 and 100),description text not null default '' check(char_length(description)<=300),unique(org_id,id));
create table public.tasks(id uuid primary key default gen_random_uuid(),org_id uuid not null,project_id uuid not null,title text not null check(char_length(trim(title)) between 1 and 100),status text not null check(status in ('Backlog','In progress','Review','Done')),priority text not null check(priority in ('Low','Medium','High')),owner text not null default '' check(char_length(owner)<=80),due date not null,foreign key(org_id,project_id) references public.projects(org_id,id) on delete restrict);
create table public.audit_log(id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations on delete cascade,actor uuid references auth.users,label text not null,at timestamptz not null default now());
create index tasks_org_idx on public.tasks(org_id);
create index audit_org_idx on public.audit_log(org_id,at desc);
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.audit_log enable row level security;
-- No direct client table access. All operations go through narrowly scoped RPCs.
revoke all on public.organizations,public.memberships,public.projects,public.tasks,public.audit_log from anon,authenticated;
create function public.my_organizations() returns jsonb language sql security definer set search_path='' as $$ select coalesce(jsonb_agg(jsonb_build_object('id',o.id,'name',o.name)),'[]'::jsonb) from public.organizations o join public.memberships m on m.org_id=o.id where m.user_id=auth.uid() $$;
create function public.create_organization(org_name text) returns uuid language plpgsql security definer set search_path='' as $$ declare new_id uuid; begin if auth.uid() is null then raise exception 'Authentication required'; end if; insert into public.organizations(name) values(trim(org_name)) returning id into new_id; insert into public.memberships values(new_id,auth.uid(),'owner'); return new_id; end $$;
create function public.workspace_snapshot(org uuid) returns jsonb language plpgsql security definer set search_path='' as $$ begin if not exists(select 1 from public.memberships where org_id=org and user_id=auth.uid()) then raise exception 'Access denied'; end if; return jsonb_build_object('version',1,'projects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'description',description) order by name) from public.projects where org_id=org),'[]'::jsonb),'tasks',coalesce((select jsonb_agg(jsonb_build_object('id',id,'title',title,'projectId',project_id,'status',status,'priority',priority,'owner',owner,'due',due) order by due) from public.tasks where org_id=org),'[]'::jsonb),'activity',coalesce((select jsonb_agg(jsonb_build_object('id',id,'label',label,'at',at) order by at desc) from (select * from public.audit_log where org_id=org order by at desc limit 100) a),'[]'::jsonb)); end $$;
create function public.workspace_mutation(org uuid,operation text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$ declare member_role text; target uuid; changed integer; begin
select role into member_role from public.memberships where org_id=org and user_id=auth.uid();
if member_role is null or member_role='viewer' then raise exception 'Access denied'; end if;
if operation like 'project.%' and member_role not in ('owner','admin') then raise exception 'Access denied'; end if;
-- Members are read-only until assignment-based authorization is implemented.
if member_role='member' then raise exception 'Member write access is not enabled'; end if;
target:=nullif(payload->>'id','')::uuid;
case operation
when 'project.save' then if target is null then insert into public.projects(org_id,name,description) values(org,trim(payload->>'name'),coalesce(payload->>'description','')); else update public.projects set name=trim(payload->>'name'),description=coalesce(payload->>'description','') where org_id=org and id=target; end if;
when 'project.delete' then delete from public.projects where org_id=org and id=target;
when 'task.save' then if target is null then insert into public.tasks(org_id,project_id,title,status,priority,owner,due) values(org,(payload->>'projectId')::uuid,trim(payload->>'title'),payload->>'status',payload->>'priority',coalesce(payload->>'owner',''),(payload->>'due')::date); else update public.tasks set project_id=(payload->>'projectId')::uuid,title=trim(payload->>'title'),status=payload->>'status',priority=payload->>'priority',owner=coalesce(payload->>'owner',''),due=(payload->>'due')::date where org_id=org and id=target; end if;
when 'task.move' then update public.tasks set status=payload->>'status' where org_id=org and id=target;
when 'task.delete' then delete from public.tasks where org_id=org and id=target;
else raise exception 'Unknown operation'; end case;
get diagnostics changed=row_count;
if changed<>1 then raise exception 'Item not found'; end if;
insert into public.audit_log(org_id,actor,label) values(org,auth.uid(),operation);
return public.workspace_snapshot(org); end $$;
revoke all on function public.my_organizations(),public.create_organization(text),public.workspace_snapshot(uuid),public.workspace_mutation(uuid,text,jsonb) from public,anon;
grant execute on function public.my_organizations(),public.create_organization(text),public.workspace_snapshot(uuid),public.workspace_mutation(uuid,text,jsonb) to authenticated;
