# Security

- Supabase Auth uses PKCE. The publishable key is the only Supabase key in the Flutter app.
- Edge Functions `smartwallet-ml` and `smartwallet-ai` require a user JWT. Requests without an Authorization header return HTTP 401.
- Render rejects `/v1/score` without a user token. It checks the token with Supabase Auth and refuses a body whose `user_id` is not the token subject.
- Row-level security keeps each user on their own rows. Service-role and LLM keys are not shipped in the APK.
- Money movement goes through the existing idempotent RPCs. The assistant and the model service cannot insert a transaction. Drafts require a confirmation tap.
- Anomaly results cannot set `blocks_transaction` to true.
- The biometric lock is local. It uses the device biometric prompt and, when Android allows it, the device PIN, pattern, or password. No fingerprint or PIN is stored in Postgres. Canceling the prompt does not sign the user out.
- Logs from the Edge Function keep only a short user-id prefix, the task, and the status. They do not record the access token.
- Account deletion is refused on the client unless the typed confirmation matches, and the server function is not deployed. A missing function deletes nothing.
- `supabase/pending/delete_own_account.sql` was reviewed on 10 Nov 2026 and was not applied. It is `security definer`, refuses a null `auth.uid()`, deletes only that auth user, revokes `public` and `anon`, and grants `execute` to `authenticated`. Because some movement tables use `ON DELETE RESTRICT` toward wallets, installing this function as written can fail and roll back instead of deleting the account. It must not be applied with `supabase db push`.

Do not run `supabase db push`. Several local migration files are not the remote history and include destructive statements.
