-- Script 06: Content-level duplicate check on raw_trans (rule R6)
-- WHY: Script 03 showed two transactions (3456218, 3507085) identical in every
--      field except trans_id. This tests the whole table for the same pattern.
-- KEY: account, date, type, operation, amount, balance, k_symbol, bank, account.
--      Balance is included because two genuine postings would leave different balances.

-- 6.1 Show the duplicate groups
SELECT account_id, date, type, operation, amount, balance, k_symbol,
       COUNT(*) AS rows_in_group, LIST(trans_id) AS trans_ids
FROM raw_trans
GROUP BY account_id, date, type, operation, amount, balance, k_symbol, bank, account
HAVING COUNT(*) > 1;

-- 6.2 Block to add to Script 04 as another UNION ALL (then rerun Script 04)
-- SELECT 'R6', 'No two transactions have identical content', 'Uniqueness',
  --(so the script 04 has been updated with R6) 
 