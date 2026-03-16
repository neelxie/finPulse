# FinPulse Analytics

A PostgreSQL analytics project modelling a financial transactions system for a small business. Built to demonstrate expert-level analytical SQL — window functions, CTE chains, recursive queries, and performance-aware schema design — applied to a realistic finance domain.

**Stack:** PostgreSQL 15 · SQL · psql  
**Domain:** Finance / Business Analytics  
**Author:** Derrick Mukisa · [linkedin.com/in/derrick-tech-expert](https://linkedin.com/in/derrick-tech-expert)

---

## Query index

| # | Business question | SQL techniques | File |
|---|---|---|---|
| 1 | Running account balance — what is the cumulative total per account at every point in time? | `SUM() OVER`, `PARTITION BY`, explicit `ROWS` frame, same-day tiebreaker | [queries/01](queries/01_running_balance.sql) |
| 2 | Month-over-month revenue change — which months grew or declined, and by how much? | `LAG()`, `DATE_TRUNC`, `NULLIF` on denominator, CTE | [queries/02](queries/02_mom_revenue_lag.sql) |
| 3 | Next-month forecast risk flag — which months are at risk of a >20% revenue drop? | `LEAD()`, multi-condition `CASE WHEN`, nested CTEs | [queries/03](queries/03_lead_forecast_flag.sql) |
| 4 | Top expense accounts ranked — where is cost concentrating, and how do ties behave? | `RANK()` vs `DENSE_RANK()`, tie detection column | [queries/04](queries/04_rank_dense_rank.sql) |
| 5 | Expense transaction tiers — which transactions need director review vs auto-approval? | `NTILE(4)`, quartile labelling, tier summary join | [queries/05](queries/05_ntile_expense_tiers.sql) |
| 6 | Monthly P&L — net profit, margin %, and YTD running profit per month | CTE chain, `FULL OUTER JOIN`, `SUM() OVER` for YTD, profitability flag | [queries/06](queries/06_cte_net_profit.sql) |
| 7 | Account hierarchy rollup — spend at every level of the chart of accounts | `WITH RECURSIVE`, path building, depth tracking, cycle guard | [queries/07](queries/07_recursive_cte_hierarchy.sql) |
| 8 | 3-month moving average — what is the smoothed revenue trend and is momentum improving? | `AVG() OVER` with `ROWS` frame, CTE composition, combined signal classification | [queries/08](queries/08_moving_average_combo.sql) |

---

## Schema

```
accounts(account_id PK, account_name, account_type, parent_account_id FK→accounts)
transactions(txn_id PK, account_id FK→accounts, txn_date, amount, category, description)
```

`account_type` is constrained to `'revenue' | 'expense' | 'asset'`.  
`parent_account_id` is nullable — NULL means root node (enables recursive CTE in query 07).

### Indexes

```sql
CREATE INDEX idx_txn_date         ON transactions (txn_date);
CREATE INDEX idx_txn_account      ON transactions (account_id);
CREATE INDEX idx_txn_date_account ON transactions (account_id, txn_date);
```

Window functions that `ORDER BY txn_date` use the date index. The composite index supports queries that filter by account and then window over dates — confirmed with `EXPLAIN ANALYZE` on a 10k-row copy of this dataset.

---

## How to run

```bash
# 1. Connect to PostgreSQL
psql -U postgres

# 2. Create schema
\i schema/01_create_tables.sql

# 3. Load seed data (72 transactions, 2024 full year)
\i schema/02_seed_data.sql

# 4. Run any query — e.g. monthly P&L
\i queries/06_cte_net_profit.sql

# 5. For wide result sets, use expanded display
\x auto
\i queries/07_recursive_cte_hierarchy.sql
```

---

## Key design decisions

**`NULLIF` on all percentage denominators**  
Every query that computes a percentage divides by `NULLIF(denominator, 0)` rather than a bare division. This prevents silent `NULL` propagation in months where revenue is zero — a real scenario when seeding partial datasets or when a new account has no prior transactions. Bare division by zero raises an error in PostgreSQL; `NULLIF` returns `NULL` cleanly, which dashboards handle correctly.

**Explicit `ROWS` frame on all window functions**  
All window functions use `ROWS BETWEEN ... AND ...` rather than relying on PostgreSQL's default `RANGE` frame. The `RANGE` frame groups rows with identical `ORDER BY` values — meaning two transactions on the same date would both show the period total rather than sequential totals. `ROWS` treats each physical row independently, which is always correct for financial ledger data.

**`FULL OUTER JOIN` in the P&L query (query 06)**  
The CTE chain in query 06 uses `FULL OUTER JOIN` to combine monthly revenue and expenses. A `LEFT JOIN` would silently drop months that had expenses but no revenue (e.g. a pre-launch period). `FULL OUTER` preserves all months from both sides, with `COALESCE(..., 0)` filling missing values — the correct approach for any financial period comparison.

**Recursive CTE over adjacency list joins (query 07)**  
The account hierarchy uses `WITH RECURSIVE` rather than a fixed chain of self-joins. Fixed self-joins only work for a known, static tree depth — they break silently when the hierarchy grows. The recursive approach handles arbitrary depth with no schema changes, includes a cycle guard (`NOT (account_id = ANY(visited_ids))`), and mirrors how hierarchical data is handled in production financial systems and dbt models.

**`txn_id` as window tiebreaker**  
All window functions that order by `txn_date` include `txn_id` as a secondary sort key. This ensures deterministic ordering when multiple transactions share a date — critical for running balance calculations where the order of same-day entries affects the intermediate totals shown to users.

---

## What I would add next

- **`EXPLAIN ANALYZE` output** for each query on a 100k-row dataset to document the index usage and query plan choices
- **Parameterised versions** of the forecast threshold (query 03) and moving average window (query 08) using PostgreSQL functions
- **A `views/` folder** with materialised views for the P&L and moving average queries — the natural next step toward a reporting pipeline
- **Integration with Google Sheets** via CSV export — query outputs feed directly into the companion Sheets dashboard in this portfolio

---

*Part of the FinPulse Analytics portfolio — SQL + Google Sheets finance analytics project.*