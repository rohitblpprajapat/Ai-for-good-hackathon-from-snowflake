# Shared Analysis Zone: AI for Good Hackathon 🌍

**Team Name:** Data Defenders  
**Team Lead:** Rohit Prajapat

## 🚀 Overview

The **Shared Analysis Zone** is a privacy-first collaborative intelligence platform designed to bridge the gap between financial silo (Banks and Insurers). It enables organizations to "join forces" to fight fraud and improve financial inclusion without ever exchanging a single row of raw customer data.

Built entirely on the **Snowflake AI Data Cloud**, this solution leverages **Data Clean Rooms** for secure collaboration and **Snowflake Cortex AI (Llama 3)** to generate plain-language risk narratives for non-technical stakeholders.

## 🎯 The Problem

1.  **The Silo:** Banks and Insurers operate in blinders, unable to see cross-industry risk patterns (e.g., "Hopping" fraud).
2.  **The Privacy Barrier:** Strict regulations (GDPR, CCPA) prevent raw data sharing.
3.  **The Inclusion Gap:** Credit-worthy customers are invisible because positive history in one sector doesn't transfer to another.

## 💡 The Solution

A Simulated Data Clean Room where:
*   **Bank** contributes encrypted Transaction Data.
*   **Insurer** contributes encrypted Claims Data.
*   **Snowflake** securely joins them using **Secure Views** and **Aggregation Policies**.
*   **Cortex AI** analyzes the aggregated results to tell a story: *"High risk detected in Age Group 18-30..."*

## 🛠️ Tech Stack

*   **Snowflake Data Clean Room**: Secure Views, Row Access Policies.
*   **Snowflake Horizon**: Governance (Tags, Masking Policies).
*   **Snowflake Cortex AI**: Llama 3 (70B) via `SNOWFLAKE.CORTEX.COMPLETE` for generative insights.
*   **Streamlit in Snowflake**: Interactive dashboard for the Consumer Analyst.
*   **Automation**: Snowflake Streams & Tasks.

## 📂 Project Structure

All SQL and Python scripts are located in the `snowflake_code/` directory:

| Script | Description |
| :--- | :--- |
| `00_check_setup.sql` | Diagnostic script to verify database and object creation. |
| `01_setup_environment.sql` | Sets up Roles (`PROVIDER_BANK`, `PROVIDER_INSURER`, `CONSUMER_ANALYST`), Databases, and Warehouses. |
| `02_generate_mock_data.sql` | Generates synthetic data for Transactions, Claims, and Demographics. |
| `03_setup_governance.sql` | Applies Horizon Tags (`PII`, `CONFIDENTIAL`) and Masking Policies. |
| `04_setup_clean_room.sql` | Implements the Clean Room logic (Secure Views, Analysis Procedures with Aggregation Policies). |
| `05_setup_automation.sql` | Sets up Streams and Tasks for daily reporting. |
| `06_verify_solution.sql` | Verification script to test privacy (access denied to raw data) and allowed analysis. |
| `07_setup_cortex_ai.sql` | Integrates Cortex AI (Llama 3) to generate risk narratives from aggregated data. |
| `08_setup_streamlit.sql` | Contains the Python code to build the Streamlit Dashboard in Snowsight. |
| `09_fix_permissions.sql` | Repair script to re-apply grants if you encounter permission errors. |

## ⚡ Deployment Instructions

1.  **Run SQL Scripts:** Execute scripts `01` through `07` in order in your Snowflake Worksheet (run as `ACCOUNTADMIN` where specified, or follow the script headers).
2.  **Deploy Streamlit:**
    *   Open `08_setup_streamlit.sql`.
    *   Create a new Streamlit App in Snowsight.
    *   Copy-paste the Python code block from the script into the Streamlit editor.
3.  **Verify:**
    *   Run `06_verify_solution.sql` to test privacy controls.
    *   Open the Streamlit App to interact with the Cross-Industry Risk Dashboard.
4.  **Troubleshoot:** If you see "Object does not exist" errors, run `09_fix_permissions.sql`.

## 📜 License

This project was created for the AI for Good Hackathon.
