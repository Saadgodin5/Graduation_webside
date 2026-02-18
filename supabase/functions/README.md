## Supabase Edge Functions (optional demo)

This folder contains an optional Edge Function used for a graduation-project demo.

### Function: `send-reminder`

- **Path**: `supabase/functions/send-reminder/index.ts`
- **What it does**: Validates the user JWT, then inserts a `workflow_runs` row for the authenticated user.

### Deploy (Supabase CLI)

From the repo root:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase functions deploy send-reminder
```

Then set function secrets in Supabase Dashboard (or via CLI):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

After deploy, the Flutter dashboard’s **Get Started** button will try to invoke this function.
