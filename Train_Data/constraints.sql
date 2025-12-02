

------------------------------------------------------------
-- 04_constraints_train_data.sql
-- Run as: TRAIN_DATA
-- Purpose: Add additional data-quality CHECK constraints
--          on top of existing PK / FK / UNIQUE / basic checks
------------------------------------------------------------

PROMPT ======================================================
PROMPT  ADDING EXTRA DATA-QUALITY CONSTRAINTS (TRAIN_DATA)
PROMPT ======================================================


------------------------------------------------------------
-- CRS_PASSENGER
--  - ZIP: exactly 5 digits
--  - PHONE: exactly 10 digits
--  - EMAIL: must contain '@'
--  (Age/minor/senior rules are handled in PL/SQL, not as
--   CHECK constraints because CHECK cannot use SYSDATE)
------------------------------------------------------------

ALTER TABLE CRS_PASSENGER
  ADD CONSTRAINT CRS_PASSENGER_CHK_ZIP
  CHECK (REGEXP_LIKE(address_zip, '^[0-9]{5}$'));

ALTER TABLE CRS_PASSENGER
  ADD CONSTRAINT CRS_PASSENGER_CHK_PHONE
  CHECK (REGEXP_LIKE(phone, '^[0-9]{10}$'));

ALTER TABLE CRS_PASSENGER
  ADD CONSTRAINT CRS_PASSENGER_CHK_EMAIL
  CHECK (INSTR(email, '@') > 1);


------------------------------------------------------------
-- CRS_TRAIN_INFO
--  - Seat counts must be positive
------------------------------------------------------------

ALTER TABLE CRS_TRAIN_INFO
  ADD CONSTRAINT CRS_TRAIN_INFO_CHK_FC_SEATS
  CHECK (total_fc_seats > 0);

ALTER TABLE CRS_TRAIN_INFO
  ADD CONSTRAINT CRS_TRAIN_INFO_CHK_ECON_SEATS
  CHECK (total_econ_seats > 0);


------------------------------------------------------------
-- CRS_DAY_SCHEDULE
--  - Only allowed: MON, TUE, WED, THU, FRI, SAT, SUN
--    (Matches TO_CHAR(travel_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'))
------------------------------------------------------------

ALTER TABLE CRS_DAY_SCHEDULE
  ADD CONSTRAINT CRS_DAY_SCHEDULE_CHK_DAY
  CHECK (day_of_week IN ('MON','TUE','WED','THU','FRI','SAT','SUN'));


------------------------------------------------------------
-- CRS_RESERVATION
--  - Travel date must be >= booking date
--    (1-week window itself is enforced in PKG_RESERVATION)
------------------------------------------------------------

ALTER TABLE CRS_RESERVATION
  ADD CONSTRAINT CRS_RESERVATION_CHK_DATES
  CHECK (travel_date >= booking_date);

PROMPT Done adding extra constraints.
