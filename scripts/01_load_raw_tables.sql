-- ============================================================
-- ============================================================
-- Step 4: Data quality rules - Berka dataset
-- Script 01: Inspect, load raw tables, check row counts
-- Source: Berka files (account.asc, client.asc, disp.asc, trans.asc) in the data/ folder
-- ============================================================

-- 1. Inspect the files (nothing is created, we only look)

-- 1.1 Account
SELECT *
FROM read_csv_auto('data/account.asc', delim=';')
LIMIT 10;

-- 1.2 Client
SELECT *
FROM read_csv_auto('data/client.asc', delim=';')
LIMIT 10;

-- 1.3 Disposition
SELECT *
FROM read_csv_auto('data/disp.asc', delim=';')
LIMIT 10;

-- 1.4 Transaction
SELECT *
FROM read_csv_auto('data/trans.asc', delim=';')
LIMIT 10;

-- 2. Load untouched copies of the source (all columns as text)

CREATE OR REPLACE TABLE raw_account AS
SELECT *
FROM read_csv_auto('/Users/helenadesoba/Desktop/D Girl/Data Governance_Materials/DG_Training/berka-dataset-master/account.asc',
                   delim=';', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_client AS
SELECT *
FROM read_csv_auto('/Users/helenadesoba/Desktop/D Girl/Data Governance_Materials/DG_Training/berka-dataset-master/client.asc',
                   delim=';', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_disp AS
SELECT *
FROM read_csv_auto('/Users/helenadesoba/Desktop/D Girl/Data Governance_Materials/DG_Training/berka-dataset-master/disp.asc',
                   delim=';', header=true, all_varchar=true);

CREATE OR REPLACE TABLE raw_trans AS
SELECT *
FROM read_csv_auto('/Users/helenadesoba/Desktop/D Girl/Data Governance_Materials/DG_Training/berka-dataset-master/trans.asc',
                   delim=';', header=true, all_varchar=true);

-- 3. Row counts (compare with the source: expect about 4500 / 5369 / 5369 / 1056320)

SELECT 'account' AS table_name, COUNT(*) AS row_count FROM raw_account
UNION ALL SELECT 'client', COUNT(*) FROM raw_client
UNION ALL SELECT 'disp',   COUNT(*) FROM raw_disp
UNION ALL SELECT 'trans',  COUNT(*) FROM raw_trans;
