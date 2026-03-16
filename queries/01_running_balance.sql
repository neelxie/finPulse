-- ============================================================
-- Query: Running account balance
-- File: queries/01_running_balance.sql
-- ============================================================
--
-- Business question:
--   What is the cumulative balance for each account at every
--   point in time? This replicates the running total column
--   on a bank statement — essential for cash flow monitoring
--   and reconciliation audits.
--
-- Approach:
--   SUM() as a window function with PARTITION BY account_id
--   resets the running total per account, so each account
--   gets its own independent balance timeline.
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW is
--   explicitly stated (rather than relying on the default
--   RANGE frame) to ensure correct behaviour when multiple
--   transactions share the same date.
--
-- Tradeoff considered:
--   The default window frame RANGE BETWEEN UNBOUNDED PRECEDING
--   AND CURRENT ROW groups all rows with the same ORDER BY
--   value — meaning two transactions on the same date would
--   both show the combined total rather than their sequential
--   totals. ROWS frame avoids this ambiguity.
--
-- Expected output columns:
--   txn_id, account_name, account_type, txn_date,
--   amount, running_balance
-- ============================================================

SELECT
  t.txn_id,
  a.account_name,
  a.account_type,
  t.txn_date,
  t.amount,
  SUM(t.amount) OVER (
    PARTITION BY t.account_id
    ORDER BY t.txn_date, t.txn_id          -- txn_id as tiebreaker for same-day transactions
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_balance
FROM transactions t
JOIN accounts a USING (account_id)
ORDER BY a.account_name, t.txn_date, t.txn_id;