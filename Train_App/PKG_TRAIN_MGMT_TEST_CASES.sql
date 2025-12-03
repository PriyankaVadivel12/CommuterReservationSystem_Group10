SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT TRAIN MANAGEMENT TEST CASES  (RUN AS TRAIN_APP)
PROMPT
PROMPT This script validates PKG_TRAIN_MGMT:
PROMPT 1) get_availability  (read-only status)
PROMPT 2) create_train      (master data insert)
PROMPT 3) update_train      (master data update)
PROMPT 4) upsert_train_schedule (service days)
PROMPT
PROMPT AVAILABILITY TESTS (T1–T12):
PROMPT T1  - Normal success (tomorrow, ECON)
PROMPT T2  - Invalid seat class                -> ORA-20020
PROMPT T3  - Train not in service              -> ORA-20021
PROMPT T4  - Invalid train number (not found)  -> ORA-20022
PROMPT T5  - NULL train number                 -> ORA-20023
PROMPT T6  - NULL travel date                  -> ORA-20024
PROMPT T7  - Travel date in the past           -> ORA-20025
PROMPT T8  - Travel date > today+7             -> ORA-20026
PROMPT T9  - Boundary: travel date = today     (SUCCESS)
PROMPT T10 - Boundary: travel date = today+7   (SUCCESS)
PROMPT T11 - Invalid train number FORMAT       -> ORA-20028
PROMPT T12 - NULL seat class                   -> ORA-20029
PROMPT
PROMPT ADMIN TESTS (A1–A8):
PROMPT A1  - create_train: happy path insert
PROMPT A2  - create_train: duplicate train#    -> ORA-20047
PROMPT A3  - create_train: invalid attributes  -> ORA-20042
PROMPT A4  - update_train: happy path update
PROMPT A5  - update_train: train not found     -> ORA-20048
PROMPT A6  - upsert_train_schedule: happy path
PROMPT A7  - upsert_train_schedule: bad day    -> ORA-20049
PROMPT A8  - upsert_train_schedule: bad flag   -> ORA-20050
PROMPT
PROMPT NOTE:
PROMPT - Admin tests use ROLLBACK so this script is repeatable.
PROMPT ============================================================


/*------------------------------------------------------------------
  T1: Availability for T101 / ECON / tomorrow (SUCCESS)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T1: Availability for T101 / ECON / tomorrow (SUCCESS)
PROMPT ============================================================
DECLARE
  v_travel_date   DATE := TRUNC(SYSDATE) + 1;
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_travel_date,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE(
    'T1: SUCCESS - T101 / ECON / '||TO_CHAR(v_travel_date,'YYYY-MM-DD')
  );
  DBMS_OUTPUT.PUT_LINE('    total_seats   = '||v_total_seats);
  DBMS_OUTPUT.PUT_LINE('    confirmed     = '||v_confirmed);
  DBMS_OUTPUT.PUT_LINE('    waitlisted    = '||v_waitlisted);
  DBMS_OUTPUT.PUT_LINE('    available     = '||v_available);
  DBMS_OUTPUT.PUT_LINE('    waitlist_left = '||v_waitlist_left);
END;
/
 

/*------------------------------------------------------------------
  T2: Invalid seat class (ERROR: ORA-20020)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T2: Invalid seat class (ERROR: ORA-20020)
PROMPT ============================================================
DECLARE
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => TRUNC(SYSDATE) + 1,
    p_seat_class    => 'BUSINESS',  -- invalid
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T2: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T2: EXPECTED ERROR (invalid class) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T3: Train not in service (ERROR: ORA-20021)
      Seed data: T202 runs Mon–Fri only. Use upcoming SATURDAY.
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T3: Train not in service (ERROR: ORA-20021)
PROMPT ============================================================
DECLARE
  v_sat           DATE := NEXT_DAY(TRUNC(SYSDATE), 'SATURDAY');
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T202',        -- weekdays only
    p_travel_date   => v_sat,         -- weekend
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T3: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T3: EXPECTED ERROR (not in service) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T4: Invalid train number (ERROR: ORA-20022)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T4: Invalid train number (ERROR: ORA-20022)
PROMPT ============================================================
DECLARE
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T999',        -- does not exist
    p_travel_date   => TRUNC(SYSDATE) + 1,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T4: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T4: EXPECTED ERROR (invalid train) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T5: NULL train number (ERROR: ORA-20023)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T5: NULL train number (ERROR: ORA-20023)
PROMPT ============================================================
DECLARE
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => NULL,              -- NULL / empty
    p_travel_date   => TRUNC(SYSDATE) + 1,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T5: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T5: EXPECTED ERROR (NULL train#) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T6: NULL travel date (ERROR: ORA-20024)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T6: NULL travel date (ERROR: ORA-20024)
PROMPT ============================================================
DECLARE
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => NULL,           -- NULL date
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T6: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T6: EXPECTED ERROR (NULL date) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T7: Travel date in the past (ERROR: ORA-20025)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T7: Travel date in the past (ERROR: ORA-20025)
PROMPT ============================================================
DECLARE
  v_past_date     DATE := TRUNC(SYSDATE) - 1;
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_past_date,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T7: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T7: EXPECTED ERROR (past date) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T8: Travel date beyond +7 days (ERROR: ORA-20026)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T8: Travel date beyond +7 days (ERROR: ORA-20026)
PROMPT ============================================================
DECLARE
  v_future_date   DATE := TRUNC(SYSDATE) + 8;
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_future_date,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T8: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T8: EXPECTED ERROR (beyond +7) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T9: Boundary test - travel date = TODAY (SUCCESS)
      Should be allowed by booking window.
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T9: Boundary test - travel date = TODAY (SUCCESS)
PROMPT ============================================================
DECLARE
  v_travel_date   DATE := TRUNC(SYSDATE);
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_travel_date,
    p_seat_class    => 'FC',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE(
    'T9: SUCCESS - T101 / FC / '||TO_CHAR(v_travel_date,'YYYY-MM-DD')
  );
  DBMS_OUTPUT.PUT_LINE('    total_seats   = '||v_total_seats);
  DBMS_OUTPUT.PUT_LINE('    confirmed     = '||v_confirmed);
  DBMS_OUTPUT.PUT_LINE('    waitlisted    = '||v_waitlisted);
  DBMS_OUTPUT.PUT_LINE('    available     = '||v_available);
  DBMS_OUTPUT.PUT_LINE('    waitlist_left = '||v_waitlist_left);
END;
/
 

/*------------------------------------------------------------------
  T10: Boundary test - travel date = TODAY + 7 (SUCCESS)
       This is the farthest day allowed by window.
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T10: Boundary test - travel date = TODAY + 7 (SUCCESS)
PROMPT ============================================================
DECLARE
  v_travel_date   DATE := TRUNC(SYSDATE) + 7;
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_travel_date,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE(
    'T10: SUCCESS - T101 / ECON / '||TO_CHAR(v_travel_date,'YYYY-MM-DD')
  );
  DBMS_OUTPUT.PUT_LINE('     total_seats   = '||v_total_seats);
  DBMS_OUTPUT.PUT_LINE('     confirmed     = '||v_confirmed);
  DBMS_OUTPUT.PUT_LINE('     waitlisted    = '||v_waitlisted);
  DBMS_OUTPUT.PUT_LINE('     available     = '||v_available);
  DBMS_OUTPUT.PUT_LINE('     waitlist_left = '||v_waitlist_left);
END;
/
 

/*------------------------------------------------------------------
  T11: Invalid train number FORMAT (ERROR: ORA-20028)
       Example: '1234' (not starting with T)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T11: Invalid train number FORMAT (ERROR: ORA-20028)
PROMPT ============================================================
DECLARE
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => '1234',           -- bad format (no leading T)
    p_travel_date   => TRUNC(SYSDATE) + 1,
    p_seat_class    => 'ECON',
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T11: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T11: EXPECTED ERROR (format) -> ' || SQLERRM
    );
END;
/
 

/*------------------------------------------------------------------
  T12: NULL seat class (ERROR: ORA-20029)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT T12: NULL seat class (ERROR: ORA-20029)
PROMPT ============================================================
DECLARE
  v_travel_date   DATE := TRUNC(SYSDATE) + 1;
  v_total_seats   NUMBER;
  v_confirmed     NUMBER;
  v_waitlisted    NUMBER;
  v_available     NUMBER;
  v_waitlist_left NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.get_availability(
    p_train_number  => 'T101',
    p_travel_date   => v_travel_date,
    p_seat_class    => NULL,            -- NULL seat class
    p_total_seats   => v_total_seats,
    p_confirmed     => v_confirmed,
    p_waitlisted    => v_waitlisted,
    p_available     => v_available,
    p_waitlist_left => v_waitlist_left
  );

  DBMS_OUTPUT.PUT_LINE('T12: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'T12: EXPECTED ERROR (NULL seat class) -> ' || SQLERRM
    );
END;
/
 

/******************************************************************
 * ADMIN TESTS FOR TRAIN MASTER DATA
 ******************************************************************/

/*------------------------------------------------------------------
  A1: create_train - happy path
      - Inserts a temporary train T7777
      - Rolls back at the end so DB is clean
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A1: create_train - happy path (INSERT)
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  DBMS_OUTPUT.PUT_LINE(
    'A1: SUCCESS - create_train(T7777), new train_id = '||v_train_id
  );
  ROLLBACK; -- revert insert so test is repeatable
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A1: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A2: create_train - duplicate train number (ERROR: ORA-20047)
      - In one transaction, insert T7777 twice
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A2: create_train - duplicate train number (ERROR: ORA-20047)
PROMPT ============================================================
DECLARE
  v_train_id1 NUMBER;
  v_train_id2 NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id1
  );

  -- Second insert with same train number should fail
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id2
  );

  DBMS_OUTPUT.PUT_LINE('A2: ERROR - this should NOT be printed');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'A2: EXPECTED ERROR (duplicate train#) -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A3: create_train - invalid attributes (source = dest)
      Expected: ORA-20042
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A3: create_train - invalid attributes (source == dest)
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T8888',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'BOSTON',   -- invalid (same as source)
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  DBMS_OUTPUT.PUT_LINE('A3: ERROR - this should NOT be printed');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'A3: EXPECTED ERROR (source==dest) -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A4: update_train - happy path
      - Create T7777, then update its attributes, then rollback
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A4: update_train - happy path (UPDATE)
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  -- Create temporary train
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  -- Update same train
  TRAIN_DATA.pkg_train_mgmt.update_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'WASHINGTON',
    p_total_fc_seats   => 50,
    p_total_econ_seats => 50,
    p_fc_seat_fare     => 200,
    p_econ_seat_fare   => 90
  );

  DBMS_OUTPUT.PUT_LINE(
    'A4: SUCCESS - update_train(T7777) after create, train_id='||v_train_id
  );
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A4: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A5: update_train - train not found (ERROR: ORA-20048)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A5: update_train - train not found (ERROR: ORA-20048)
PROMPT ============================================================
BEGIN
  TRAIN_DATA.pkg_train_mgmt.update_train(
    p_train_number     => 'T9999',        -- assume not seeded
    p_source_station   => 'BOSTON',
    p_dest_station     => 'CHICAGO',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80
  );

  DBMS_OUTPUT.PUT_LINE('A5: ERROR - this should NOT be printed');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'A5: EXPECTED ERROR (train not found) -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A6: upsert_train_schedule - happy path
      - Create T7777, then upsert schedule for MON with 'Y'
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A6: upsert_train_schedule - happy path
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  -- Create temporary train
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  -- Upsert schedule for Monday
  TRAIN_DATA.pkg_train_mgmt.upsert_train_schedule(
    p_train_number  => 'T7777',
    p_day_of_week   => 'MON',
    p_is_in_service => 'Y'
  );

  DBMS_OUTPUT.PUT_LINE(
    'A6: SUCCESS - upsert_train_schedule(T7777, MON, Y), train_id='||v_train_id
  );
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A6: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A7: upsert_train_schedule - invalid day_of_week (ERROR: ORA-20049)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A7: upsert_train_schedule - invalid day_of_week (ERROR: ORA-20049)
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  -- Create temporary train
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  -- Invalid day string, e.g. 'XYZ' -> no row in CRS_DAY_SCHEDULE
  TRAIN_DATA.pkg_train_mgmt.upsert_train_schedule(
    p_train_number  => 'T7777',
    p_day_of_week   => 'XYZ',
    p_is_in_service => 'Y'
  );

  DBMS_OUTPUT.PUT_LINE('A7: ERROR - this should NOT be printed');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'A7: EXPECTED ERROR (bad day_of_week) -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
 

/*------------------------------------------------------------------
  A8: upsert_train_schedule - invalid is_in_service flag (ERROR: ORA-20050)
  -----------------------------------------------------------------*/
PROMPT ============================================================
PROMPT A8: upsert_train_schedule - invalid is_in_service flag (ERROR: ORA-20050)
PROMPT ============================================================
DECLARE
  v_train_id NUMBER;
BEGIN
  -- Create temporary train
  TRAIN_DATA.pkg_train_mgmt.create_train(
    p_train_number     => 'T7777',
    p_source_station   => 'BOSTON',
    p_dest_station     => 'NEW YORK',
    p_total_fc_seats   => 40,
    p_total_econ_seats => 40,
    p_fc_seat_fare     => 150,
    p_econ_seat_fare   => 80,
    p_train_id         => v_train_id
  );

  -- Invalid flag 'X'
  TRAIN_DATA.pkg_train_mgmt.upsert_train_schedule(
    p_train_number  => 'T7777',
    p_day_of_week   => 'MON',
    p_is_in_service => 'X'
  );

  DBMS_OUTPUT.PUT_LINE('A8: ERROR - this should NOT be printed');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'A8: EXPECTED ERROR (bad is_in_service flag) -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
