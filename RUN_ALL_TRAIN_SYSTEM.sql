-- =========================================================
-- TRAIN MANAGEMENT SYSTEM  - FULL BUILD SCRIPT
-- Run from: SYSTEM (or other DBA user)
-- This script:
--   1. Drops TRAIN_DATA / TRAIN_APP (optional clean rebuild)
--   2. Creates both schemas (SchemaCreation.sql)
--   3. Builds tables, constraints, seed data
--   4. Compiles all packages
--   5. Creates report views + report package
--   6. Grants EXECUTE/SELECT to TRAIN_APP
--
-- NOTE: Passwords here must match SchemaCreation.sql
--       TRAIN_DATA password : TrainData#2025
--       TRAIN_APP  password : TrainApp#2025
-- =========================================================

SET ECHO ON
SET DEFINE OFF

PROMPT ================================================
PROMPT 0. Dropping users TRAIN_APP / TRAIN_DATA (if any)
PROMPT ================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP USER TRAIN_APP CASCADE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP USER TRAIN_DATA CASCADE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN
      RAISE;
    END IF;
END;
/

PROMPT Users dropped (if existed).
PROMPT

-- ======================================================
-- 1. CREATE SCHEMAS (TRAIN_DATA, TRAIN_APP)
-- ======================================================
PROMPT ================================================
PROMPT 1. Creating schemas and basic grants
PROMPT ================================================

@SchemaCreation/SchemaCreation.sql

PROMPT Schemas created.
PROMPT

-- ======================================================
-- 2. BUILD OBJECTS IN TRAIN_DATA
-- ======================================================
PROMPT ================================================
PROMPT 2. Connecting as TRAIN_DATA and creating objects
PROMPT ================================================

CONNECT TRAIN_DATA/"TrainData#2025"

-- 2.1 Tables + PK/FK + basic constraints
PROMPT 2.1 Creating tables (DDL) ...
@Train_Data/train_data_DDL.sql

PROMPT 2.2 Applying additional constraints ...
@Train_Data/constraints.sql

-- 2.3 Seed data (day-of-week, trains, schedules, sample data)
PROMPT 2.3 Inserting seed data ...
@Train_Data/train_data_dml.sql

COMMIT;

-- ======================================================
-- 3. COMPILE BUSINESS PACKAGES
-- ======================================================
PROMPT ================================================
PROMPT 3. Compiling business PL/SQL packages
PROMPT ================================================

PROMPT 3.1 PKG_PASSENGER_MGMT
@Train_Data/PKG_PASSENGER_MGMT.sql

PROMPT 3.2 PKG_TRAIN_MGMT
@Train_Data/PKG_TRAIN_MGMT.sql

PROMPT 3.3 PKG_RESERVATION
@Train_Data/PKG_RESERVATION.sql

-- ======================================================
-- 4. REPORTING VIEWS + REPORT PACKAGE
-- ======================================================
PROMPT ================================================
PROMPT 4. Creating reporting views and report package
PROMPT ================================================

@Train_Data/reports_views_and_pkg.sql

-- ======================================================
-- 5. GRANTS TO TRAIN_APP
-- ======================================================
PROMPT ================================================
PROMPT 5. Granting EXECUTE / SELECT to TRAIN_APP
PROMPT ================================================

@Train_Data/grant_access.sql

PROMPT All grants applied.
PROMPT

-- ======================================================
-- 6. DONE
-- ======================================================
PROMPT ================================================
PROMPT BUILD COMPLETE
PROMPT - Schemas: TRAIN_DATA, TRAIN_APP
PROMPT - Tables / constraints / seed data created
PROMPT - Packages compiled
PROMPT - Reporting views and package created
PROMPT - TRAIN_APP has EXECUTE and SELECT privileges
PROMPT ================================================

-- Optionally switch to TRAIN_APP at the end:
CONNECT TRAIN_APP/"TrainApp#2025"

PROMPT You are now connected as TRAIN_APP.
PROMPT You can run:
PROMPT   @Train_App/PKG_PASSENGER_MGMT_TEST_CASES.sql
PROMPT   @Train_App/PKG_TRAIN_MGMT_TEST_CASES.sql
PROMPT   @Train_App/PKG_RESERVATION_TEST_CASES.sql
PROMPT   @Train_App/TEST_reports.sql
