# FinPulse Analytics

## What this is
A PostgreSQL analytics project modelling a financial transactions
system. Built to demonstrate expert-level SQL across window functions,
CTEs, recursive queries, and performance-aware schema design —
applied to a real finance domain.

**Stack:** PostgreSQL 15 · SQL · psql

---

## Query index

| # | Business question | Techniques | File |
|---|-------------------|------------|------|
| 1 | Running account balance | SUM OVER, PARTITION BY, ROWS frame | queries/01 |
| 2 | Month-over-month revenue change | LAG, DATE_TRUNC, NULLIF | queries/02 |
| 3 | Next-month forecast risk flag | LEAD, CASE WHEN | queries/03 |
| 4 | Top expense accounts ranked | RANK vs DENSE_RANK | queries/04 |
| 5 | Expense quartile tiers | NTILE(4), spend labelling | queries/05 |
| 6 | Monthly P&L (revenue − expenses) | CTE chain, FULL OUTER JOIN | queries/06 |
| 7 | Account hierarchy rollup | WITH RECURSIVE, depth tracking | queries/07 |
| 8 | 3-month moving average + trend | AVG OVER ROWS, CTE combo | queries/08 |

---

## How to run

```bash
psql -U postgres
\i schema/01_create_tables.sql
\i schema/02_seed_data.sql

# Run any query
\i queries/02_mom_revenue_lag.sql
```

---

## Schema

```
accounts(account_id, account_name, account_type, parent_account_id)
transactions(txn_id, account_id, txn_date, amount, category, description)
```

Indexes on `txn_date` and `account_id` — window function queries
ORDER BY date benefit measurably from the date index on larger datasets.

---

## Key design decisions

- **NULLIF on all percentage denominators** — prevents silent NULL
  propagation in month-over-month calculations
- **Explicit ROWS frame on window functions** — `ROWS BETWEEN
  UNBOUNDED PRECEDING AND CURRENT ROW` is more predictable than
  the default RANGE frame when dates have gaps
- **Recursive CTE for account hierarchy** — chosen over adjacency
  list joins because it handles arbitrary depth cleanly

---

Built by Derrick Mukisa · [www.linkedin.com/in/derrick-tech-expert](https://www.linkedin.com/in/derrick-tech-expert) ·