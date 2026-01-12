-- 08_setup_streamlit.sql
-- Purpose: Create a Streamlit App inside Snowflake (SiS) to visualize the Shared Analysis Zone.
-- Instructions: Run this script. Then go to Snowsight -> Streamlit and open "Shared Analysis Dashboard".

USE ROLE ACCOUNTADMIN;
USE DATABASE SHARED_ANALYSIS_ZONE;
USE SCHEMA CLEANROOM;

CREATE STAGE IF NOT EXISTS ROOT_STAGE;

CREATE OR REPLACE STREAMLIT SHARED_ANALYSIS_DASHBOARD
ROOT_LOCATION = '@SHARED_ANALYSIS_ZONE.CLEANROOM.ROOT_STAGE' -- Ensure you have a stage or use default if supported
MAIN_FILE = 'streamlit_app.py'
QUERY_WAREHOUSE = 'ANALYTICS_WH'
COMMENT = 'AI for Good: Shared Analysis Zone Dashboard';

-- Note: Since we cannot easily upload the .py file via SQL script without a PUT command (which requires SnowSQL),
-- We will assume the user will COPY-PASTE the Python code below into the Snowsight Editor.
-- This script creates the placeholder object.

/*
DATA TO PASTE INTO SNOWSIGHT STREAMLIT EDITOR:
-------------------------------------------------------
import streamlit as st
from snowflake.snowpark.context import get_active_session

# Page Config
st.set_page_config(layout="wide", page_title="AI for Good: Shared Analysis Zone")

# Header & Context
st.title("🛡️ Shared Analysis Zone: Fraud & Inclusion")
st.markdown("""
**Context**: This dashboard allows the **Bank** and **Insurer** to collaborate on fraud detection 
*without* sharing raw customer data. It uses a **Snowflake Data Clean Room**.
""")

# Sidebar: Controls
st.sidebar.header("Analysis Controls")
min_age = st.sidebar.slider("Minimum Age", 18, 90, 18)
max_age = st.sidebar.slider("Maximum Age", 18, 90, 90)
run_btn = st.sidebar.button("Run Secure Analysis", type="primary")

session = get_active_session()

if run_btn:
    with st.spinner("Querying Secure Views in Clean Room & Generating AI Insights..."):
        # 1. Run the Aggregate Analysis Procedure
        # We call the stored procedure we created in step 04
        cmd_sql = f"SELECT * FROM TABLE(SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD({min_age}, {max_age}))"
        df_risk = session.sql(cmd_sql).to_pandas()
        
        if not df_risk.empty:
            # Layout: Metrics & Narrative
            col1, col2 = st.columns([2, 1])
            
            with col1:
                st.subheader("📊 Cross-Industry Risk Segments")
                st.dataframe(df_risk, use_container_width=True)
                
                # Simple Chart
                st.bar_chart(df_risk.set_index("AGE_BUCKET")[["TOTAL_TXN_AMOUNT", "TOTAL_CLAIM_AMOUNT"]])

            with col2:
                st.subheader("🤖 Cortex AI Analysis")
                
                # Check if we have results to send to AI
                # We pick the highest risk row to analyze
                top_risk = df_risk.iloc[0] # Sorted by Risk Score in SQL
                
                # Call the Cortex Wrapper Function we created in step 07
                ai_cmd = f"""
                SELECT SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_RISK_NARRATIVE(
                    '{top_risk['AGE_BUCKET']}', 
                    {top_risk['TOTAL_TXN_AMOUNT']}, 
                    {top_risk['TOTAL_CLAIM_AMOUNT']}, 
                    {top_risk['RISK_SCORE']}
                ) as NARRATIVE
                """
                ai_narrative = session.sql(ai_cmd).collect()[0]['NARRATIVE']
                
                st.info(ai_narrative)
                st.markdown("**Why this matters:** This insight was generated without the Analyst seeing a single raw transaction.")
        else:
            st.warning("No data found for this range (or suppressed by Privacy Policy).")

else:
    st.info("👈 Adjust filters and click 'Run Secure Analysis' to start.")

-------------------------------------------------------
*/
