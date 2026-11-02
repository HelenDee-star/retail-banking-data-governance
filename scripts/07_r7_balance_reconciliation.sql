-- Script 07: Balance reconciliation on raw_trans (rule R7)
-- WHY: BCBS 239 expects data that can be aggregated and trusted. If the balance
--      after each transaction does not follow from the previous balance and the
--      amount, then totals built from these rows cannot be trusted.
-- LIMIT: Berka has dates but no times, so the order of same-day transactions is
--      unknown. Only transactions that are alone on their date, and follow one
--      that was also alone on its date, are checked.
-- SIGN: PRIJEM (credit) adds; VYDAJ and VYBER (debit, Assumption 25 / DQ2) subtract.

WITH t AS (
    SELECT account_id,
           TRY_STRPTIME(date, '%y%m%d') AS d,
           trans_id,
           CASE WHEN type = 'PRIJEM' THEN 1 ELSE -1 END * CAST(amount AS DECIMAL(18,2)) AS signed_amount,
           CAST(balance AS DECIMAL(18,2)) AS bal
    FROM raw_trans),
n AS (
    SELECT *, COUNT(*) OVER (PARTITION BY account_id, d) AS per_day
    FROM t),
r AS (
    SELECT *,
           LAG(bal)     OVER (PARTITION BY account_id ORDER BY d, CAST(trans_id AS BIGINT)) AS prev_bal,
           LAG(per_day) OVER (PARTITION BY account_id ORDER BY d, CAST(trans_id AS BIGINT)) AS prev_per_day
    FROM n)
SELECT 'R7' AS rule_id,
       'Balance equals previous balance plus signed amount' AS rule,
       'Consistency' AS dimension,
       COUNT(*) FILTER (WHERE per_day = 1 AND prev_per_day = 1) AS rows_checked,
       COUNT(*) FILTER (WHERE per_day = 1 AND prev_per_day = 1
                        AND bal <> prev_bal + signed_amount) AS rows_failed,
       COUNT(*) FILTER (WHERE per_day = 1 AND prev_per_day = 1
                        AND bal <> prev_bal + signed_amount
                        AND ABS(bal - (prev_bal + signed_amount)) <= 0.5) AS failed_by_under_0_50
FROM r;