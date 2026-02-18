# Backend roadmap (Supabase + Flutter)

Your app already uses **Supabase** for auth and a `profiles` table. Below is what to do later when you add real data and features.

---

## 1. Finish Supabase setup (if not done)

- In [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**, run `supabase_setup.sql` so that:
  - Row Level Security (RLS) is enabled on `profiles`
  - Users can only read/update their own profile
  - A profile is auto-created when a user signs up
- Ensure the `profiles` table has columns: `id` (uuid, PK), `email` (text). Add any extra columns (e.g. `display_name`, `avatar_url`) as needed.

---

## 2. Add tables for your features

When you’re ready to persist data (workflows, history, integrations, etc.), create tables in Supabase and keep using the same project.

Examples you might add later:

| Table            | Purpose                          | Key columns (examples)                    |
|------------------|-----------------------------------|-------------------------------------------|
| `workflows`      | Saved automations / workflows     | `id`, `user_id`, `name`, `config`, `created_at` |
| `workflow_runs`  | History of runs (dashboard table) | `id`, `workflow_id`, `user_id`, `status`, `executed_at` |
| `integrations`   | Connected apps (Gmail, Notion…)   | `id`, `user_id`, `provider`, `credentials_encrypted`, `created_at` |
| `chat_messages`  | AstroBot chat history             | `id`, `user_id`, `role` (user/bot), `content`, `created_at` |
| `user_settings`  | Quick settings (voice, notifications) | `user_id`, `key`, `value`             |

- Always add a `user_id` (uuid, references `auth.uid()`) so you can enforce “user sees only their data.”
- In **SQL Editor** you can create tables and then enable RLS and add policies (see step 3).

---

## 3. Secure every table with RLS

For each new table:

1. **Enable RLS**: `ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;`
2. **Policies**: Only allow access where `auth.uid() = user_id` (e.g. `SELECT`, `INSERT`, `UPDATE`, `DELETE`).

Example for a `workflows` table:

```sql
ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own workflows"
  ON workflows FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

Do the same idea for `workflow_runs`, `integrations`, `chat_messages`, `user_settings`, etc.

---

## 4. Use Supabase from Flutter

- **Read**: `Supabase.instance.client.from('workflows').select().eq('user_id', userId)`
- **Insert**: `Supabase.instance.client.from('workflows').insert({...})`
- **Update**: `Supabase.instance.client.from('workflows').update({...}).eq('id', id).eq('user_id', userId)`
- **Delete**: `Supabase.instance.client.delete().eq('id', id).eq('user_id', userId)`

Always filter by `user_id` (from `Supabase.instance.client.auth.currentUser?.id`) so RLS and your app stay in sync.

---

## 5. Optional: Edge Functions and Realtime

- **Edge Functions**: Use when you need custom logic (e.g. call external APIs, run workflows, send emails). Create in Supabase and call from Flutter via `functions.invoke('your-function-name', body: {...})`.
- **Realtime**: Use Supabase Realtime if you want live updates (e.g. live chat, workflow status) instead of polling.

---

## 6. Security and config

- **Secrets**: Do not put API keys or secrets in Flutter code. Use Supabase Edge Functions or a small backend to call third‑party APIs; store secrets in Supabase Dashboard → **Settings → Edge Function secrets** (or env in a separate server).
- **Supabase URL/anon key**: For production, consider loading from environment (e.g. `--dart-define=SUPABASE_URL=...`) or a config file that is not committed, so you can use different keys per environment.

---

## Summary checklist (for later)

- [ ] Run `supabase_setup.sql` and confirm `profiles` + trigger work
- [ ] Run `supabase_tables_and_rls.sql` to create workflows, workflow_runs, integrations, chat_messages, user_settings and their RLS policies (all use `auth.uid() = user_id`)
- [ ] In Flutter, replace mock data with `client.from('...').select/insert/update/delete`
- [ ] (Optional) Add Edge Functions for heavy or secret operations
- [ ] (Optional) Use Realtime for live UI updates
- [ ] Move Supabase URL/keys to env or config and keep secrets out of the repo

Once you decide the first feature (e.g. “save workflows” or “chat history”), you can add one table + RLS + Flutter calls and repeat.
