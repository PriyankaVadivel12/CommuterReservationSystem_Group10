------------------------------------------------------------------
-- TRAIN MANAGEMENT SYSTEM - SCHEMA SETUP
-- Run as a user with CREATE USER privilege (e.g., DAMG6210)
-- This script creates:
--   1) TRAIN_DATA  - owns tables, sequences, packages
--   2) TRAIN_APP   - executes packages (no tables)
------------------------------------------------------------------

-----------------------------
-- (OPTIONAL) CLEANUP FIRST
-----------------------------
-- Uncomment these lines if you need to rerun the script
-- and the users already exist.

--DROP USER TRAIN_APP  CASCADE;
--DROP USER TRAIN_DATA CASCADE;

------------------------------------------------------------
-- 1. SCHEMA: TRAIN_DATA  (DATA OWNER + PL/SQL)
------------------------------------------------------------
CREATE USER TRAIN_DATA
  IDENTIFIED BY "TrainData#2025"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP;

-- Allow this user to connect
GRANT CREATE SESSION TO TRAIN_DATA;

-- Allow creation of all objects needed for the assignment
GRANT CREATE TABLE,
      CREATE VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE SYNONYM
TO TRAIN_DATA;

-- Give unlimited space in USERS tablespace (adjust if needed)
ALTER USER TRAIN_DATA QUOTA UNLIMITED ON USERS;


------------------------------------------------------------
-- 2. SCHEMA: TRAIN_APP   (APPLICATION / RUNNER USER)
------------------------------------------------------------
CREATE USER TRAIN_APP
  IDENTIFIED BY "TrainApp#2025"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP;

-- Allow this user to connect
GRANT CREATE SESSION TO TRAIN_APP;

-- Do not allow owning data (no quota / no tables)
ALTER USER TRAIN_APP QUOTA 0 ON USERS;




