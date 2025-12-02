SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT TRAIN MANAGEMENT TEST CASES  (RUN AS TRAIN_APP)
PROMPT
PROMPT This script validates PKG_TRAIN_MGMT.get_availability
PROMPT
PROMPT COVERS:
PROMPT  T1  - Normal success (tomorrow, ECON)
PROMPT  T2  - Invalid seat class           -> ORA-20020
PROMPT  T3  - Train not in service         -> ORA-20021
PROMPT  T4  - Invalid train number         -> ORA-20022
PROMPT  T5  - NULL train number            -> ORA-20023
PROMPT  T6  - NULL travel date             -> ORA-20024
PROMPT  T7  - Travel date in the past      -> ORA-20025
PROMPT  T8  - Travel date > today+7        -> ORA-20026
PROMPT  T9  - Boundary: travel date = today     (SUCCESS)
PROMPT  T10 - Boundary: travel date = today+7   (SUCCESS)
PROMPT  T11 - Invalid train number FORMAT  -> ORA-20028
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
