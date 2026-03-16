-- ============================================================
-- Query: Account hierarchy rollup with recursive CTE
-- File: queries/07_recursive_cte_hierarchy.sql
-- ============================================================
--
-- Business question:
--   The chart of accounts is hierarchical — "Salaries" and
--   "Contractor Fees" both roll up into "People Costs", which
--   rolls up into "Operating Expenses". How much has been
--   spent at each level of the hierarchy? Produce the full
--   path and aggregated spend for every node in the tree.
--   This is how enterprise financial systems report by cost
--   centre, department, and division simultaneously.
--
-- Approach:
--   WITH RECURSIVE traverses the accounts tree top-down:
--     Anchor member    — selects root accounts (parent IS NULL)
--     Recursive member — joins each account to its children,
--                        building the path string and depth counter
--   After traversal, a second CTE aggregates all transactions
--   per account. The final SELECT joins tree + spend and uses
--   REPEAT('  ', depth) to produce an indented display name
--   that visualises hierarchy level directly in query output.
--
--   Cycle protection: WITH RECURSIVE in PostgreSQL detects
--   infinite loops when a node references itself directly.
--   For multi-hop cycles (A→B→A), add a visited array:
--   ARRAY[account_id] and check NOT (account_id = ANY(visited)).
--   Not included here as the schema uses a clean tree structure,
--   but noted for production use.
--
-- Prerequisite setup:
--   Run the ALTER TABLE and UPDATE statements below to add
--   parent_account_id relationships before executing the query.
--
-- Tradeoff considered:
--   Alternative: adjacency list with multiple self-joins.
--   e.g. JOIN accounts parent ON a.parent_id = parent.id
--        JOIN accounts grandparent ON parent.parent_id = grandparent.id
--   Rejected because: (1) it only works for a fixed, known depth,
--   (2) it breaks silently when hierarchy changes, and (3) recursive
--   CTE handles arbitrary depth with no schema changes required.
--
-- Expected output columns:
--   account_id, full_path, depth, indented_name,
--   direct_spend, total_spend_in_subtree
-- ============================================================

-- ============================================================
-- SETUP: Run once to create hierarchy (skip if already done)
-- ============================================================
-- ALTER TABLE accounts
--   ADD COLUMN IF NOT EXISTS parent_account_id
--   INT REFERENCES accounts(account_id);
--
-- Example hierarchy:
--   "Operating Expenses" (id=6) is a root node
--   "Rent"      (id=3) rolls up to Operating Expenses
--   "Salaries"  (id=4) rolls up to Operating Expenses
--   "Utilities" (id=5) rolls up to Operating Expenses
--
-- UPDATE accounts SET parent_account_id = 6
--   WHERE account_id IN (3, 4, 5);
-- ============================================================

WITH RECURSIVE account_tree AS (

  -- Anchor: start from root accounts (no parent)
  SELECT
    account_id,
    account_name,
    account_type,
    parent_account_id,
    account_name::TEXT                    AS full_path,
    0                                     AS depth,
    ARRAY[account_id]                     AS visited_ids   -- cycle guard
  FROM accounts
  WHERE parent_account_id IS NULL

  UNION ALL

  -- Recursive: attach children to their parents
  SELECT
    a.account_id,
    a.account_name,
    a.account_type,
    a.parent_account_id,
    (at.full_path || ' > ' || a.account_name)::TEXT  AS full_path,
    at.depth + 1                                      AS depth,
    at.visited_ids || a.account_id                   AS visited_ids
  FROM accounts a
  JOIN account_tree at
    ON a.parent_account_id = at.account_id
  WHERE NOT (a.account_id = ANY(at.visited_ids))   -- prevent cycles
),

account_spend AS (
  -- Direct spend per account (not including children)
  SELECT
    account_id,
    ROUND(SUM(amount), 2)  AS direct_spend
  FROM transactions
  GROUP BY account_id
),

tree_with_spend AS (
  SELECT
    at.account_id,
    at.full_path,
    at.depth,
    at.account_type,
    REPEAT('    ', at.depth) || at.account_name  AS indented_name,
    COALESCE(asp.direct_spend, 0)                AS direct_spend
  FROM account_tree at
  LEFT JOIN account_spend asp USING (account_id)
)

SELECT
  account_id,
  full_path,
  depth,
  indented_name,
  account_type,
  direct_spend,

  -- Subtree total: sum of this node + all descendant nodes
  -- Achieved by summing spend for all accounts whose path
  -- starts with this node's path prefix
  ROUND((
    SELECT COALESCE(SUM(asp2.direct_spend), 0)
    FROM tree_with_spend tws2
    JOIN account_spend asp2 ON tws2.account_id = asp2.account_id
    WHERE tws2.full_path LIKE (full_path || '%')
  ), 2)                    AS subtree_total_spend

FROM tree_with_spend
ORDER BY full_path;