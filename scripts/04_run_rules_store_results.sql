-- ============================================================
-- Step 4: Data quality rules - Berka dataset
-- Script 04: Run all rules and store the results
-- R = core rules (from the glossary), F = additional findings
-- v2: R6 (content-level duplicate check) added
-- ============================================================

CREATE OR REPLACE TABLE dq_results AS
SELECT rule_id, rule, dimension, rows_checked, rows_failed,
       ROUND(100.0 * rows_failed / rows_checked, 4) AS pct_failed
FROM (

    -- R1a: Account identifier is unique (account_id stands in for IBAN)
    SELECT 'R1a' AS rule_id,
           'Account ID is unique' AS rule,
           'Uniqueness' AS dimension,
           COUNT(*) AS rows_checked,
           COUNT(*) - COUNT(DISTINCT account_id) AS rows_failed
    FROM raw_account

    UNION ALL
    -- R1b: Account identifier is not empty
    SELECT 'R1b', 'Account ID is not empty', 'Completeness',
           COUNT(*),
           COUNT(*) FILTER (WHERE account_id IS NULL OR TRIM(account_id) = '')
    FROM raw_account

    UNION ALL
    -- R2: Transaction amount is greater than zero
    SELECT 'R2', 'Transaction amount is greater than zero', 'Validity',
           COUNT(*),
           COUNT(*) FILTER (WHERE TRY_CAST(amount AS DECIMAL(18,2)) <= 0)
    FROM raw_trans

    UNION ALL
    -- R3: Transaction date is not before the account opening date
    SELECT 'R3', 'Transaction date not before account opening date', 'Consistency',
           COUNT(*),
           COUNT(*) FILTER (WHERE TRY_STRPTIME(t.date, '%y%m%d') < TRY_STRPTIME(a.date, '%y%m%d'))
    FROM raw_trans t
    JOIN raw_account a ON t.account_id = a.account_id

    UNION ALL
    -- R4: Direction can be mapped to D or C (PRIJEM -> C, VYDAJ and VYBER -> D)
    SELECT 'R4', 'Direction maps to D or C (Assumption 25 / DQ2)', 'Validity',
           COUNT(*),
           COUNT(*) FILTER (WHERE type NOT IN ('PRIJEM', 'VYDAJ', 'VYBER'))
    FROM raw_trans

    UNION ALL
    -- R5: Customer has at least one Account Holder (OWNER). Review queue, not an error
    SELECT 'R5', 'Customer has at least one OWNER (for review)', 'Completeness',
           (SELECT COUNT(*) FROM raw_client),
           (SELECT COUNT(*) FROM raw_client c
            WHERE NOT EXISTS (SELECT 1 FROM raw_disp d
                              WHERE d.client_id = c.client_id AND d.type = 'OWNER'))   UNION ALL
    -- R9: Every Account has at least one Account Holder (OWNER)
    SELECT 'R9', 'Account has at least one OWNER', 'Completeness',
           (SELECT COUNT(*) FROM raw_account),
           (SELECT COUNT(*) FROM raw_account a
            WHERE NOT EXISTS (SELECT 1 FROM raw_disp d
                              WHERE d.account_id = a.account_id AND d.type = 'OWNER'))


    UNION ALL
    -- R6: No two transactions have identical content (balance included in the key)
    SELECT 'R6', 'No two transactions have identical content', 'Uniqueness',
           (SELECT COUNT(*) FROM raw_trans),
           (SELECT COALESCE(SUM(n - 1), 0) FROM (
                SELECT COUNT(*) AS n
                FROM raw_trans
                GROUP BY account_id, date, type, operation, amount, balance, k_symbol, bank, account
                HAVING COUNT(*) > 1)) 

    UNION ALL
    -- F1: Source finding - type holds a value the documentation does not allow
    SELECT 'F1', 'Source: type holds only documented values (PRIJEM, VYDAJ)', 'Validity',
           COUNT(*),
           COUNT(*) FILTER (WHERE type NOT IN ('PRIJEM', 'VYDAJ'))
    FROM raw_trans

    UNION ALL
    -- F2: Channel is required (L6), but operation is empty
    SELECT 'F2', 'Operation (Channel) is not empty', 'Completeness',
           COUNT(*),
           COUNT(*) FILTER (WHERE operation IS NULL OR TRIM(operation) = '')
    FROM raw_trans
);

-- Show the results
SELECT * FROM dq_results ORDER BY rule_id;


 
