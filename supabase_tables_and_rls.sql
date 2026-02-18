-- =============================================================================
-- Run this in Supabase Dashboard → SQL Editor AFTER supabase_setup.sql
-- Creates: workflows, workflow_runs, integrations, chat_messages, user_settings
-- Enables RLS and adds auth.uid() = user_id policies on every table.
-- =============================================================================
--
-- HOW THIS WORKS
-- --------------
-- 1. TABLES
--    Each CREATE TABLE defines a table in your Supabase (Postgres) database.
--    - id / user_id: UUIDs. user_id is always the logged-in user (from Supabase Auth).
--    - REFERENCES auth.users(id): Links the row to Supabase's built-in auth table.
--    - ON DELETE CASCADE: When a user is deleted, their rows in this table are deleted too.
--
-- 2. ROW LEVEL SECURITY (RLS)
--    ALTER TABLE ... ENABLE ROW LEVEL SECURITY turns on RLS. Then no one can read or
--    write any row unless a POLICY allows it.
--
-- 3. POLICIES
--    CREATE POLICY "Users can manage own workflows" means:
--    - FOR ALL: Applies to SELECT, INSERT, UPDATE, DELETE.
--    - USING (auth.uid() = user_id): You can only see/update/delete rows where the
--      row's user_id equals the current user's id (auth.uid() comes from the JWT).
--    - WITH CHECK (auth.uid() = user_id): You can only insert/update rows where
--      user_id is your own id. So User A cannot create a row with user_id = User B.
--
-- 4. IN YOUR FLUTTER APP
--    When you call Supabase from Flutter, the client sends the user's JWT. Supabase
--    uses that to set auth.uid() and then applies these policies. So:
--    - client.from('workflows').select()  → returns only rows where user_id = you
--    - client.from('workflows').insert({user_id: currentUser.id, ...})  → allowed
--    - If you try to read another user's row, the policy blocks it and you get nothing.
--
-- 5. INDEXES
--    The CREATE INDEX lines at the end speed up queries that filter by user_id or
--    sort by time (e.g. "get my workflow runs, newest first").
--
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Create profiles table (only if you haven't run supabase_setup.sql yet)
--    If profiles already exists, skip this block.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 2. Workflows – saved automations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workflows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  config jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own workflows"
  ON public.workflows FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 3. Workflow runs – history (dashboard table)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workflow_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id uuid REFERENCES public.workflows(id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  intent text,
  status text NOT NULL DEFAULT 'pending',  -- e.g. 'Completed', 'In Progress', 'Failed'
  executed_at timestamptz DEFAULT now()
);

ALTER TABLE public.workflow_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own workflow_runs"
  ON public.workflow_runs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 4. Integrations – connected apps (Gmail, Notion, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider text NOT NULL,           -- e.g. 'Gmail', 'Notion', 'Telegram'
  credentials_encrypted text,      -- store encrypted tokens/keys; decrypt in Edge Function
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own integrations"
  ON public.integrations FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 5. Chat messages – AstroBot chat history
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'bot')),
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat_messages"
  ON public.chat_messages FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 6. User settings – quick settings (voice, notifications, preferences)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  key text NOT NULL,                 -- e.g. 'voice_input', 'notifications'
  value text,                        -- e.g. 'true', 'false', or JSON
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, key)
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own user_settings"
  ON public.user_settings FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- Optional: indexes for common filters
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_workflows_user_id ON public.workflows(user_id);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_user_id ON public.workflow_runs(user_id);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_executed_at ON public.workflow_runs(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_integrations_user_id ON public.integrations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at DESC);
