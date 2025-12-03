SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  RESERVATION MANAGEMENT TEST CASES  (TRAIN_APP USER)
PROMPT
PROMPT  This script validates PKG_RESERVATION:
PROMPT    • book_ticket
PROMPT    • cancel_ticket
PROMPT
PROMPT  BUSINESS RULES COVERED:
PROMPT    • Only 1-week advance booking allowed
PROMPT    • Train must be in service on the chosen travel date
PROMPT    • Class must be FC or ECON only
PROMPT    • Max 40 CONFIRMED seats per class per train/date
PROMPT    • Max 5 WAITLISTED seats per class per train/date
PROMPT    • If capacity + waitlist full → booking rejected
PROMPT    • Cancellation of CONFIRMED ticket promotes first WAITLISTED
PROMPT    • Waitlist positions are reordered (1,2,3,…) after changes
PROMPT
PROMPT  ERROR SCENARIOS TESTED:
PROMPT    • Invalid passenger id
PROMPT    • Invalid train number / not in service
PROMPT    • Invalid seat class
PROMPT    • Booking beyond allowed window
PROMPT    • Cancel non-existent booking id
PROMPT    • Cancel already cancelled ticket
PROMPT
PROMPT  NOTE:
PROMPT    • Run AFTER:
PROMPT        - Tables + constraints created in TRAIN_DATA
PROMPT        - Seed data (trains, schedules, passengers) inserted
PROMPT        - Packages compiled and EXECUTE granted to TRAIN_APP
PROMPT ============================================================



------------------------------------------------------------
-- R1: Basic ECON booking for T101 tomorrow (SUCCESS)
------------------------------------------------------------
DECLARE
  v_booking_id  NUMBER;
  v_seat_status VARCHAR2(20);
  v_travel_date DATE := TRUNC(SYSDATE) + 1;
BEGIN
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 1,        -- assumes passenger_id = 1 exists
    p_train_number => 'T101',
    p_travel_date  => v_travel_date,
    p_seat_class   => 'ECON',
    p_booking_id   => v_booking_id,
    p_seat_status  => v_seat_status
  );

  DBMS_OUTPUT.PUT_LINE(
    'R1: SUCCESS - booking_id='||v_booking_id||
    ', status='||v_seat_status||
    ', travel_date='||TO_CHAR(v_travel_date,'YYYY-MM-DD')
  );

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R1: UNEXPECTED ERROR -> '||SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------

SELECT booking_id, passenger_id, train_id, travel_date,
       seat_class, seat_status, waitlist_position
FROM   TRAIN_DATA.CRS_RESERVATION
WHERE  booking_id = (SELECT MAX(booking_id)
                     FROM TRAIN_DATA.CRS_RESERVATION);
/
------------------------------------------------------------


------------------------------------------------------------
-- R2: Booking > 1 week ahead (ERROR: ORA-20031)
------------------------------------------------------------
DECLARE
  v_booking_id  NUMBER;
  v_seat_status VARCHAR2(20);
  v_travel_date DATE := TRUNC(SYSDATE) + 8;  -- > 7 days
BEGIN
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 1,
    p_train_number => 'T101',
    p_travel_date  => v_travel_date,
    p_seat_class   => 'ECON',
    p_booking_id   => v_booking_id,
    p_seat_status  => v_seat_status
  );

  DBMS_OUTPUT.PUT_LINE('R2: ERROR - should NOT succeed');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R2: EXPECTED ERROR (1-week rule) -> '||SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- R3: Train not in service on given date (ERROR: ORA-20033)
--     T202 runs Mon–Fri only; we use upcoming SATURDAY.
------------------------------------------------------------
DECLARE
  v_booking_id  NUMBER;
  v_seat_status VARCHAR2(20);
  v_sat         DATE := NEXT_DAY(TRUNC(SYSDATE), 'SATURDAY');
BEGIN
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 1,
    p_train_number => 'T202',   -- weekdays only in seed data
    p_travel_date  => v_sat,    -- weekend
    p_seat_class   => 'ECON',
    p_booking_id   => v_booking_id,
    p_seat_status  => v_seat_status
  );

  DBMS_OUTPUT.PUT_LINE('R3: ERROR - should NOT succeed');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'R3: EXPECTED ERROR (train not in service) -> '||SQLERRM
    );
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- R4: Capacity and waitlist for T101 / ECON on date D
--     - 40 CONFIRMED, then 5 WAITLISTED, then error
------------------------------------------------------------
DECLARE
  v_travel_date   DATE   := TRUNC(SYSDATE) + 2;  -- still within +7
  v_pid           NUMBER;
  v_booking_id    NUMBER;
  v_seat_status   VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('R4: Filling ECON seats on T101 for '||
                       TO_CHAR(v_travel_date,'YYYY-MM-DD'));

  FOR i IN 1..46 LOOP
    -- Create unique passenger for each booking
    TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
      p_first_name   => 'R4_User'||i,
      p_middle_name  => NULL,
      p_last_name    => 'Test',
      p_dob          => DATE '1990-01-01',
      p_addr_line1   => 'Addr '||i,
      p_city         => 'City',
      p_state        => 'ST',
      p_zip          => '00000',
      p_email        => 'r4_user'||i||'@crs.test',
      p_phone        => '910' || LPAD(i,3,'0'),
      p_passenger_id => v_pid
    );

    BEGIN
      TRAIN_DATA.pkg_reservation.book_ticket(
        p_passenger_id => v_pid,
        p_train_number => 'T101',
        p_travel_date  => v_travel_date,
        p_seat_class   => 'ECON',
        p_booking_id   => v_booking_id,
        p_seat_status  => v_seat_status
      );

      DBMS_OUTPUT.PUT_LINE(
        'R4: Booking #'||RPAD(i,2)||' -> id='||v_booking_id||
        ', status='||v_seat_status
      );

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
          'R4: Booking #'||i||
          ' EXPECTED ERROR (no seats/waitlist) -> '||SQLERRM
        );
        EXIT;
    END;
  END LOOP;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R4: UNEXPECTED ERROR (outer block) -> '||SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------

-- Verify counts: should be 40 CONFIRMED + 5 WAITLISTED
SELECT seat_status, COUNT(*) AS cnt
FROM   TRAIN_DATA.CRS_RESERVATION
WHERE  train_id    = 1                       -- T101
AND    travel_date = TRUNC(SYSDATE) + 2
AND    seat_class  = 'ECON'
GROUP  BY seat_status;
/

SELECT booking_id, passenger_id, seat_status, waitlist_position
FROM   TRAIN_DATA.CRS_RESERVATION
WHERE  train_id    = 1
AND    travel_date = TRUNC(SYSDATE) + 2
AND    seat_class  = 'ECON'
ORDER  BY booking_id;
/
------------------------------------------------------------


------------------------------------------------------------
-- R5: Cancellation promotes first WAITLISTED and reorders
------------------------------------------------------------
DECLARE
  v_travel_date    DATE := TRUNC(SYSDATE) + 2;
  v_confirmed_id   NUMBER;
  v_before_conf    NUMBER;
  v_before_wait    NUMBER;
  v_after_conf     NUMBER;
  v_after_wait     NUMBER;
BEGIN
  -- Choose one CONFIRMED booking (lowest id)
  SELECT MIN(booking_id)
  INTO   v_confirmed_id
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  train_id      = 1
  AND    travel_date   = v_travel_date
  AND    seat_class    = 'ECON'
  AND    seat_status   = 'CONFIRMED';

  DBMS_OUTPUT.PUT_LINE('R5: Cancelling CONFIRMED booking_id='||v_confirmed_id);

  -- BEFORE stats
  SELECT SUM(CASE WHEN seat_status='CONFIRMED' THEN 1 ELSE 0 END),
         SUM(CASE WHEN seat_status='WAITLISTED' THEN 1 ELSE 0 END)
  INTO   v_before_conf, v_before_wait
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  train_id    = 1
  AND    travel_date = v_travel_date
  AND    seat_class  = 'ECON';

  DBMS_OUTPUT.PUT_LINE('R5 BEFORE: confirmed='||v_before_conf||
                       ', waitlisted='||v_before_wait);

  -- Cancel (promote first waitlisted inside package)
  TRAIN_DATA.pkg_reservation.cancel_ticket(v_confirmed_id);
  COMMIT;

  -- AFTER stats
  SELECT SUM(CASE WHEN seat_status='CONFIRMED' THEN 1 ELSE 0 END),
         SUM(CASE WHEN seat_status='WAITLISTED' THEN 1 ELSE 0 END)
  INTO   v_after_conf, v_after_wait
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  train_id    = 1
  AND    travel_date = v_travel_date
  AND    seat_class  = 'ECON';

  DBMS_OUTPUT.PUT_LINE('R5 AFTER : confirmed='||v_after_conf||
                       ', waitlisted='||v_after_wait);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R5: UNEXPECTED ERROR -> '||SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------

SELECT booking_id, seat_status, waitlist_position
FROM   TRAIN_DATA.CRS_RESERVATION
WHERE  train_id    = 1
AND    travel_date = TRUNC(SYSDATE) + 2
AND    seat_class  = 'ECON'
ORDER  BY seat_status, waitlist_position, booking_id;
/
------------------------------------------------------------


------------------------------------------------------------
-- R6: Error scenarios:
--   R6.1 Invalid passenger id
--   R6.2 Invalid seat class
--   R6.3 Cancel invalid booking id
--   R6.4 Cancel same ticket twice
------------------------------------------------------------

-- R6.1: Invalid passenger id (ORA-20035)
DECLARE
  v_booking_id  NUMBER;
  v_seat_status VARCHAR2(20);
BEGIN
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 999999,              -- invalid
    p_train_number => 'T101',
    p_travel_date  => TRUNC(SYSDATE)+1,
    p_seat_class   => 'ECON',
    p_booking_id   => v_booking_id,
    p_seat_status  => v_seat_status
  );

  DBMS_OUTPUT.PUT_LINE('R6.1: ERROR - should NOT succeed');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R6.1: EXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


-- R6.2: Invalid seat class (ORA-20032)
DECLARE
  v_booking_id  NUMBER;
  v_seat_status VARCHAR2(20);
BEGIN
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 1,
    p_train_number => 'T101',
    p_travel_date  => TRUNC(SYSDATE)+1,
    p_seat_class   => 'BUSINESS',   -- invalid
    p_booking_id   => v_booking_id,
    p_seat_status  => v_seat_status
  );

  DBMS_OUTPUT.PUT_LINE('R6.2: ERROR - should NOT succeed');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R6.2: EXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


-- R6.3: Cancel invalid booking id (ORA-20037)
BEGIN
  TRAIN_DATA.pkg_reservation.cancel_ticket(
    p_booking_id => 9999999
  );

  DBMS_OUTPUT.PUT_LINE('R6.3: ERROR - should NOT succeed');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R6.3: EXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


-- R6.4: Cancel same ticket twice (ORA-20036)
DECLARE
  v_booking_id  NUMBER;
  v_status      VARCHAR2(30);
BEGIN
  -- Create a valid booking
  TRAIN_DATA.pkg_reservation.book_ticket(
    p_passenger_id => 1,
    p_train_number => 'T101',
    p_travel_date  => TRUNC(SYSDATE)+1,
    p_seat_class   => 'ECON',
    p_booking_id   => v_booking_id,
    p_seat_status  => v_status
  );

  DBMS_OUTPUT.PUT_LINE('R6.4: Created booking_id='||v_booking_id||
                       ', status='||v_status);

  -- First cancel: OK
  TRAIN_DATA.pkg_reservation.cancel_ticket(v_booking_id);
  DBMS_OUTPUT.PUT_LINE('R6.4: First cancellation OK');

  -- Second cancel: should fail
  TRAIN_DATA.pkg_reservation.cancel_ticket(v_booking_id);
  DBMS_OUTPUT.PUT_LINE('R6.4: ERROR - second cancel should NOT succeed');

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'R6.4: EXPECTED ERROR on 2nd cancel -> ' || SQLERRM
    );
    ROLLBACK;
END;
/
------------------------------------------------------------
-- END OF RESERVATION MANAGEMENT TESTS
------------------------------------------------------------
