-- ============================================================
-- Step 4: Data quality rules - Berka dataset
-- Script 03: Profile raw_account, raw_client, raw_disp
-- ============================================================


-- 1. Direction mapping: which type/operation combinations exist?
SELECT type, operation, COUNT(*) AS row_count
FROM raw_trans
GROUP BY type, operation
ORDER BY type, operation;


-- 2. Uniqueness of the account identifier
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT account_id) AS distinct_ids
FROM raw_account;


-- 3. Uniqueness of the client identifier
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT client_id) AS distinct_ids
FROM raw_client;


-- 4. Accounts with no OWNER (rule: every Account has at least one Account Holder)
SELECT COUNT(*) AS accounts_without_owner
FROM raw_account a
WHERE NOT EXISTS (
    SELECT 1 FROM raw_disp d
    WHERE d.account_id = a.account_id
      AND d.type = 'OWNER'
);


-- 5. Clients with no OWNER record (these would be reported for review)
SELECT COUNT(*) AS clients_without_owner_record
FROM raw_client c
WHERE NOT EXISTS (
    SELECT 1 FROM raw_disp d
    WHERE d.client_id = c.client_id
      AND d.type = 'OWNER'
);


-- 6. Accounts opened AFTER their first transaction (date level only)
SELECT COUNT(*) AS opened_after_first_transaction
FROM raw_account a
JOIN (
    SELECT account_id,
           MIN(TRY_STRPTIME(date, '%y%m%d')) AS first_trans_date
    FROM raw_trans
    GROUP BY account_id
) t ON a.account_id = t.account_id
WHERE TRY_STRPTIME(a.date, '%y%m%d') > t.first_trans_date;

-- 7. What are the credits with no operation? (basis for "internal posting")
SELECT k_symbol, COUNT(*) AS row_count
FROM raw_trans
WHERE operation IS NULL OR TRIM(operation) = ''
GROUP BY k_symbol
ORDER BY row_count DESC;


--  8. Are the 869 clients exactly the DISPONENT clients?
SELECT COUNT(*) AS clients_only_disponent
FROM raw_client c
WHERE NOT EXISTS (SELECT 1 FROM raw_disp d WHERE d.client_id = c.client_id AND d.type = 'OWNER')
  AND EXISTS     (SELECT 1 FROM raw_disp d WHERE d.client_id = c.client_id AND d.type = 'DISPONENT');


