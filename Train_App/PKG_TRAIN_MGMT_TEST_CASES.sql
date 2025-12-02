SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  TRAIN MANAGEMENT TEST CASES  (TRAIN_APP USER)
PROMPT
PROMPT  This script validates PKG_TRAIN_MGMT:
PROMPT    -> get_availability  (success + errors)
PROMPT    -> Checks for:
PROMPT         - Valid train + valid class
PROMPT         - Invalid seat class
PROMPT         - Train not in service for date
PROMPT         - Invalid train-to-day mapping
PROMPT
PROMPT  NOTE:
PROMPT    Run this script as TRAIN_APP after all seed data is loaded.
PROMPT ============================================================


------------------------------------------------------------
-- T1: Availability for T101 / ECON / tomorrow (SUCCESS)
------------------------------------------------------------
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

  DBMS_OUTPUT.PUT_LINE('T1: AVAILABILITY FOR T101 / ECON / '||
                       TO_CHAR(v_travel_date,'YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('  total_seats   = '||v_total_seats);
  DBMS_OUTPUT.PUT_LINE('  confirmed     = '||v_confirmed);
  DBMS_OUTPUT.PUT_LINE('  waitlisted    = '||v_waitlisted);
  DBMS_OUTPUT.PUT_LINE('  available     = '||v_available);
  DBMS_OUTPUT.PUT_LINE('  waitlist_left = '||v_waitlist_left);

  COMMIT;  -- no DML here, but keeps transaction clean

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('T1: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- T2: Invalid seat class (ERROR: ORA-20020)
------------------------------------------------------------
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
  COMMIT;  -- would only run if no error (which is wrong case)

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('T2: EXPECTED ERROR (invalid class) -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- T3: Train not in service on that day (ORA-20021)
-- From seed data: T202 runs Mon–Fri only.
-- We take upcoming SATURDAY.
------------------------------------------------------------
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
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('T3: EXPECTED ERROR (not in service) -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- T4: Invalid train number (ERROR: ORA-20022)
------------------------------------------------------------
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
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('T4: EXPECTED ERROR (invalid train) -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------
-- END OF TRAIN MANAGEMENT TESTS
------------------------------------------------------------
