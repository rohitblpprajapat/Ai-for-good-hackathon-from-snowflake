-- 04_setup_clean_room.sql
-- Purpose: Implement the logical "Clean Room" by creating secure views and approved analysis procedures.

USE WAREHOUSE ANALYTICS_WH;

-- ==========================================
-- 1. PROVIDERS SHARE DATA VIA SECURE VIEWS
-- ==========================================

-- Bank shares Transaction Data + Customer Demographics (linked)
USE ROLE PROVIDER_BANK;
CREATE OR REPLACE SECURE VIEW SHARED_ANALYSIS_ZONE.CLEANROOM.BANK_DATA_VIEW AS
SELECT 
    t.CUSTOMER_ID,
    c.AGE,
    c.REGION,
    c.INCOME_BRACKET,
    c.HAS_SUBSIDY,
    t.AMOUNT,
    t.IS_FRAUDULENT
FROM BANK_DB.RAW.TRANSACTIONS t
JOIN BANK_DB.RAW.CUSTOMERS c ON t.CUSTOMER_ID = c.CUSTOMER_ID;

-- Insurer shares Claims Data
USE ROLE PROVIDER_INSURER;
CREATE OR REPLACE SECURE VIEW SHARED_ANALYSIS_ZONE.CLEANROOM.INSURER_DATA_VIEW AS
SELECT 
    CUSTOMER_ID,
    CLAIM_AMOUNT,
    POLICY_TYPE,
    STATUS
FROM INSURER_DB.RAW.CLAIMS;

-- ==========================================
-- 2. CREATE ANALYSIS TEMPLATES (Stored Procedures)
-- ==========================================
-- These procedures act as the "Approved Questions" the Consumer can ask.
-- They run with OWNER rights (which we will set to a role that has access to both views).

USE ROLE ACCOUNTADMIN; 
-- We use ACCOUNTADMIN here to simulate the 'Clean Room Provider' role that bridges the gap.
-- In a real DCR, this would be the Provider's account executing the Consumer's request or a specific Cross-Database role.

CREATE OR REPLACE PROCEDURE SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD(MIN_AGE INT, MAX_AGE INT)
RETURNS TABLE (AGE_BUCKET VARCHAR, TOTAL_TXN_AMOUNT NUMBER, TOTAL_CLAIM_AMOUNT NUMBER, RISK_SCORE NUMBER)
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    res RESULTSET;
BEGIN
    res := (
        SELECT 
            CASE 
                WHEN AGE BETWEEN 18 AND 30 THEN '18-30'
                WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
                WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
                ELSE '70+' 
            END AS AGE_BUCKET,
            SUM(b.AMOUNT) AS TOTAL_TXN_AMOUNT,
            SUM(i.CLAIM_AMOUNT) AS TOTAL_CLAIM_AMOUNT,
            -- Simple Risk Score simulation: Ratio of Fraud Txns + Claim Rejections
            (SUM(CASE WHEN b.IS_FRAUDULENT THEN 1 ELSE 0 END) + 
             SUM(CASE WHEN i.STATUS = 'Rejected' THEN 1 ELSE 0 END)) AS RISK_SCORE
        FROM SHARED_ANALYSIS_ZONE.CLEANROOM.BANK_DATA_VIEW b
        JOIN SHARED_ANALYSIS_ZONE.CLEANROOM.INSURER_DATA_VIEW i ON b.CUSTOMER_ID = i.CUSTOMER_ID
        WHERE b.AGE BETWEEN :MIN_AGE AND :MAX_AGE
        GROUP BY 1
        HAVING COUNT(DISTINCT b.CUSTOMER_ID) >= 5 -- Aggregation Policy: Minimum 5 entities
        ORDER BY RISK_SCORE DESC
    );
    RETURN TABLE(res);
END;
$$;

-- Second Analysis: Subsidy Impact Analysis
CREATE OR REPLACE PROCEDURE SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_SUBSIDY_GAP()
RETURNS TABLE (REGION VARCHAR, AVG_CLAIM_AMOUNT NUMBER, SUBSIDY_UTILIZATION_RATE NUMBER)
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    res RESULTSET;
BEGIN
    res := (
        SELECT 
            b.REGION,
            AVG(i.CLAIM_AMOUNT) AS AVG_CLAIM_AMOUNT,
            (COUNT_IF(b.HAS_SUBSIDY) / COUNT(*)) * 100 AS SUBSIDY_UTILIZATION_RATE
        FROM SHARED_ANALYSIS_ZONE.CLEANROOM.BANK_DATA_VIEW b
        JOIN SHARED_ANALYSIS_ZONE.CLEANROOM.INSURER_DATA_VIEW i ON b.CUSTOMER_ID = i.CUSTOMER_ID
        GROUP BY 1
        HAVING COUNT(DISTINCT b.CUSTOMER_ID) >= 10
    );
    RETURN TABLE(res);
END;
$$;

-- ==========================================
-- 3. GRANT ACCESS TO CONSUMER
-- ==========================================
GRANT USAGE ON PROCEDURE SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD(INT, INT) TO ROLE CONSUMER_ANALYST;
GRANT USAGE ON PROCEDURE SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_SUBSIDY_GAP() TO ROLE CONSUMER_ANALYST;

SELECT 'Clean Room Logic Setup Complete' as Status;
