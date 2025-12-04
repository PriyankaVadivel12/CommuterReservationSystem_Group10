SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  REPORTING / AUDIT DEMO  (TRAIN_APP USER)
PROMPT ============================================================

------------------------------------------------------------
-- RPT1: Daily train load for a given date
--   Use a date where you know you have reservations
--   Example: tomorrow, or TRUNC(SYSDATE)+2 for your big test
------------------------------------------------------------
DECLARE
  v_date DATE := TRUNC(SYSDATE) + 1;  -- adjust as needed
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Calling PKG_CRS_REPORTS.print_daily_train_load ---');
  TRAIN_DATA.PKG_CRS_REPORTS.print_daily_train_load(p_travel_date => v_date);
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- RPT2: Passenger booking history by email
--   Use an email you know exists, e.g. aryaa.updated@example.com
------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Calling PKG_CRS_REPORTS.print_passenger_history ---');
  TRAIN_DATA.PKG_CRS_REPORTS.print_passenger_history(
    p_email => 'arch.updated@example.com'
  );
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- RPT3: Waitlist detail for a given train/date/class
--   Example: T101, ECON, same date used in capacity tests
------------------------------------------------------------
DECLARE
  v_date DATE := TRUNC(SYSDATE) + 1;  -- same date as RPT1
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Calling PKG_CRS_REPORTS.print_waitlist_detail ---');
  TRAIN_DATA.PKG_CRS_REPORTS.print_waitlist_detail(
    p_train_number => 'T101',
    p_travel_date  => v_date,
    p_seat_class   => 'ECON'
  );
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- Optional: show views directly via SELECT
------------------------------------------------------------

-- View 1: Daily load (all trains / all dates)
SELECT *
FROM   TRAIN_DATA.CRS_V_TRAIN_DAILY_LOAD
ORDER  BY travel_date, train_number, seat_class;
/

-- View 2: Passenger summary
SELECT *
FROM   TRAIN_DATA.CRS_V_PASSENGER_BOOKING_SUMMARY
ORDER  BY passenger_id;
/

-- View 3: Waitlist detail
SELECT *
FROM   TRAIN_DATA.CRS_V_WAITLIST_DETAIL
ORDER  BY travel_date, train_number, seat_class, waitlist_position;
/
------------------------------------------------------------
-- END REPORTING DEMO
------------------------------------------------------------
