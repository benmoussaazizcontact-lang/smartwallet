-- Applied remotely via MCP as enable_pg_cron_recurring.
-- Recurring transactions run hourly in PostgreSQL, not only when the app is open.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.schedule(
  'process-due-recurring-hourly',
  '20 * * * *',
  $job$SELECT app_private.process_due_recurring_transactions();$job$
)
WHERE NOT EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'process-due-recurring-hourly'
);
