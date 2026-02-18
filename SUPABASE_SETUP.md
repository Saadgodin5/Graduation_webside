## Supabase setup checklist (for this project)

This repo already contains the database schema and Row Level Security (RLS) policies you need in `supabase_tables_and_rls.sql`.

### 1) Create the tables + RLS policies

In Supabase:

- Open **Dashboard → SQL Editor**
- Paste the full contents of `supabase_tables_and_rls.sql`
- Run it

You should end up with these `public` tables:

- `profiles`
- `workflows`
- `workflow_runs`
- `integrations`
- `chat_messages`
- `user_settings`

### 2) Verify RLS is enabled

In Supabase:

- Go to **Table editor → (table) → RLS / Security**
- Confirm **RLS is enabled** for each table above
- Confirm each table has a policy that enforces **`auth.uid() = user_id`** (or `profiles.id = auth.uid()` if you later add profiles policies/triggers)

### 3) Seed a little demo data (optional but recommended)

After you sign up and log in from the Flutter app at least once, run this SQL (replace the UUID with your user id from **Auth → Users**):

```sql
-- Replace with your auth.users id:
--   select id,email from auth.users;
do $$
declare
  uid uuid := '00000000-0000-0000-0000-000000000000';
begin
  insert into public.workflow_runs (user_id, intent, status, executed_at)
  values
    (uid, 'Send weekly report', 'Completed', now() - interval '10 minutes'),
    (uid, 'Create reminder', 'Completed', now() - interval '35 minutes'),
    (uid, 'Check weather', 'In Progress', now() - interval '1 hour')
  on conflict do nothing;

  insert into public.chat_messages (user_id, role, content)
  values
    (uid, 'bot', 'Hi, I''m AstroBot. What would you like to automate today?'),
    (uid, 'user', 'Show me my recent automated tasks.')
  on conflict do nothing;

  insert into public.user_settings (user_id, key, value)
  values
    (uid, 'voice_input', 'false'),
    (uid, 'notifications', 'true'),
    (uid, 'preferences', 'true')
  on conflict (user_id, key) do update set value = excluded.value, updated_at = now();
end $$;
```

### 4) What “works” in the app after this

- **Workflow History** pulls from `workflow_runs`
- **Live Chat** loads/saves `chat_messages`
- **Quick Settings** loads/saves `user_settings`

If any of those screens show an error, it usually means one of:

- you didn’t run `supabase_tables_and_rls.sql`
- RLS is enabled but policies are missing
- you are in “Guest user” / preview mode (no session)

