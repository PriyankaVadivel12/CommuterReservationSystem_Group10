SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT RESERVATION MANAGEMENT TEST CASES  (RUN AS TRAIN_APP)
PROMPT
PROMPT This script validates PKG_RESERVATION_MGMT:
PROMPT   1) book_ticket   (booking + waitlist logic)
PROMPT   2) cancel_ticket (cancellation + promotion)
PROMPT
PROMPT AVAILABILITY / BOOKING TESTS (R1–R7):
PROMPT   R1  - Happy path booking -> CONFIRMED
PROMPT   R2  - Happy path booking -> WAITLISTED when full
PROMPT   R3  - No capacity and no waitlist -> ORA-20062
PROMPT   R4  - NULL passenger id           -> ORA-20060
PROMPT   R5  - Non-existent passenger id   -> ORA-20061
PROMPT   R6  - NULL seat class  (from train pkg -> ORA-20029)
PROMPT   R7  - Invalid seat class (from train pkg -> ORA-20020)
PROMPT
PROMPT CANCELLATION TESTS (R8–R12):
PROMPT   R8  - cancel_ticket on CONFIRMED -> promotes first WAITLISTED
PROMPT   R9  - cancel_ticket on WAITLISTED -> compacts waitlist positions
PROMPT   R10 - cancel_ticket with NULL booking id -> ORA-20063
PROMPT   R11 - cancel_ticket with missing booking id -> ORA-20064
PROMPT   R12 - cancel_ticket on already CANCELLED -> ORA-20065
PROMPT
PROMPT NOTE:
PROMPT   - Each test uses ROLLBACK so this script is repeatable.
PROMPT   - Assumes train T101 exists and is in service for today..today+7.
PROMPT ============================================================


/*------------------------------------------------------------------
  Helper: show a sample passenger_id from TRAIN_DATA.CRS_PASSENGER
  -----------------------------------------------------------------*/
DECLARE
  v_sample_passenger_id NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_sample_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  DBMS_OUTPUT.PUT_LINE('Helper: sample passenger_id = '||v_sample_passenger_id);
END;
/
-------------------------------------------------------------------------------
-- R1: book_ticket - happy path (CONFIRMED)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R1: book_ticket - happy path (CONFIRMED)
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
  v_travel_date       DATE := TRUNC(SYSDATE) + 1;  -- tomorrow
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R1: SUCCESS - booking_id='||v_booking_id||
                       ', status='||v_final_status||
                       ', waitlist_pos='||NVL(TO_CHAR(v_waitlist_position),'NULL'));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R1: UNEXPECTED ERROR -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R2: book_ticket - becomes WAITLISTED when seats full
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R2: book_ticket - becomes WAITLISTED when seats full
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
  v_travel_date       DATE := TRUNC(SYSDATE) + 1;
  v_dummy_booking     NUMBER;
  v_dummy_status      VARCHAR2(20);
  v_dummy_pos         NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  -- Fill ECON seats (40) as CONFIRMED
  FOR i IN 1..40 LOOP
    TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
      p_passenger_id      => v_passenger_id,
      p_train_number      => 'T101',
      p_travel_date       => v_travel_date,
      p_seat_class        => 'ECON',
      p_booking_id        => v_dummy_booking,
      p_final_status      => v_dummy_status,
      p_waitlist_position => v_dummy_pos
    );
  END LOOP;

  -- Next booking should be WAITLISTED
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R2: SUCCESS - booking_id='||v_booking_id||
                       ', status='||v_final_status||
                       ', waitlist_pos='||v_waitlist_position);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R2: UNEXPECTED ERROR -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R3: book_ticket - no seats and no waitlist (ERROR: ORA-20062)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R3: book_ticket - no seats and no waitlist (ERROR: ORA-20062)
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_dummy_booking     NUMBER;
  v_dummy_status      VARCHAR2(20);
  v_dummy_pos         NUMBER;
  v_travel_date       DATE := TRUNC(SYSDATE) + 1;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  -- Fill 40 CONFIRMED + 5 WAITLISTED for ECON class => 45 bookings
  FOR i IN 1..45 LOOP
    TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
      p_passenger_id      => v_passenger_id,
      p_train_number      => 'T101',
      p_travel_date       => v_travel_date,
      p_seat_class        => 'ECON',
      p_booking_id        => v_dummy_booking,
      p_final_status      => v_dummy_status,
      p_waitlist_position => v_dummy_pos
    );
  END LOOP;

  -- 46th booking must fail with ORA-20062
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_dummy_booking,
    p_final_status      => v_dummy_status,
    p_waitlist_position => v_dummy_pos
  );

  DBMS_OUTPUT.PUT_LINE('R3: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R3: EXPECTED ERROR (no capacity) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R4: book_ticket - NULL passenger id (ERROR: ORA-20060)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R4: book_ticket - NULL passenger id (ERROR: ORA-20060)
PROMPT ============================================================
DECLARE
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
BEGIN
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => NULL,
    p_train_number      => 'T101',
    p_travel_date       => TRUNC(SYSDATE)+1,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R4: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R4: EXPECTED ERROR (NULL passenger) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R5: book_ticket - non-existent passenger (ERROR: ORA-20061)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R5: book_ticket - non-existent passenger (ERROR: ORA-20061)
PROMPT ============================================================
DECLARE
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
  v_fake_passenger_id NUMBER := 999999999;  -- assume not present
BEGIN
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_fake_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => TRUNC(SYSDATE)+1,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R5: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R5: EXPECTED ERROR (unknown passenger) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R6: book_ticket - NULL seat class (ERROR: ORA-20029 from train pkg)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R6: book_ticket - NULL seat class (ERROR: ORA-20029)
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => TRUNC(SYSDATE)+1,
    p_seat_class        => NULL,
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R6: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R6: EXPECTED ERROR (NULL seat_class) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R7: book_ticket - invalid seat class (ERROR: ORA-20020 from train pkg)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R7: book_ticket - invalid seat class (ERROR: ORA-20020)
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => TRUNC(SYSDATE)+1,
    p_seat_class        => 'BUSINESS',  -- invalid
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R7: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R7: EXPECTED ERROR (invalid seat_class) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R8: cancel_ticket - CONFIRMED cancellation promotes WAITLISTED
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R8: cancel_ticket - CONFIRMED cancellation promotes WAITLISTED
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_travel_date       DATE := TRUNC(SYSDATE) + 1;
  v_booking_conf      NUMBER;
  v_booking_wait      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
  v_dummy_id          NUMBER;
  v_dummy_status      VARCHAR2(20);
  v_dummy_pos         NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  -- 40 confirmed bookings
  FOR i IN 1..40 LOOP
    TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
      p_passenger_id      => v_passenger_id,
      p_train_number      => 'T101',
      p_travel_date       => v_travel_date,
      p_seat_class        => 'ECON',
      p_booking_id        => v_dummy_id,
      p_final_status      => v_dummy_status,
      p_waitlist_position => v_dummy_pos
    );
    IF i = 1 THEN
      v_booking_conf := v_dummy_id;  -- CONFIRMED booking to cancel
    END IF;
  END LOOP;

  -- First waitlisted booking
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_wait,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  DBMS_OUTPUT.PUT_LINE('R8: Setup - CONF booking='||v_booking_conf||
                       ', WAIT booking='||v_booking_wait||
                       ', wait_pos='||v_waitlist_position);

  -- Cancel CONFIRMED; waitlisted must be promoted
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => v_booking_conf);

  SELECT seat_status, waitlist_position
  INTO   v_final_status, v_waitlist_position
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  booking_id = v_booking_wait;

  DBMS_OUTPUT.PUT_LINE('R8: AFTER CANCEL - booking '||v_booking_wait||
                       ' -> status='||v_final_status||
                       ', waitlist_pos='||NVL(TO_CHAR(v_waitlist_position),'NULL'));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R8: UNEXPECTED ERROR -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R9: cancel_ticket - WAITLISTED cancellation compacts positions
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R9: cancel_ticket - WAITLISTED cancellation compacts positions
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_travel_date       DATE := TRUNC(SYSDATE) + 1;
  v_dummy_id          NUMBER;
  v_dummy_status      VARCHAR2(20);
  v_dummy_pos         NUMBER;
  v_bk_wait1          NUMBER;
  v_bk_wait2          NUMBER;
  v_bk_wait3          NUMBER;
  v_status1           VARCHAR2(20);
  v_status3           VARCHAR2(20);
  v_pos1              NUMBER;
  v_pos3              NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  -- fill all seats first (40 confirmed)
  FOR i IN 1..40 LOOP
    TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
      p_passenger_id      => v_passenger_id,
      p_train_number      => 'T101',
      p_travel_date       => v_travel_date,
      p_seat_class        => 'ECON',
      p_booking_id        => v_dummy_id,
      p_final_status      => v_dummy_status,
      p_waitlist_position => v_dummy_pos
    );
  END LOOP;

  -- create 3 waitlisted bookings
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_bk_wait1,
    p_final_status      => v_dummy_status,
    p_waitlist_position => v_dummy_pos
  );

  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_bk_wait2,
    p_final_status      => v_dummy_status,
    p_waitlist_position => v_dummy_pos
  );

  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => v_travel_date,
    p_seat_class        => 'ECON',
    p_booking_id        => v_bk_wait3,
    p_final_status      => v_dummy_status,
    p_waitlist_position => v_dummy_pos
  );

  DBMS_OUTPUT.PUT_LINE('R9: Setup - wait1='||v_bk_wait1||
                       ', wait2='||v_bk_wait2||
                       ', wait3='||v_bk_wait3);

  -- cancel middle WAITLISTED booking
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => v_bk_wait2);

  -- check remaining waitlist positions
  SELECT seat_status, waitlist_position
  INTO   v_status1, v_pos1
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  booking_id = v_bk_wait1;

  SELECT seat_status, waitlist_position
  INTO   v_status3, v_pos3
  FROM   TRAIN_DATA.CRS_RESERVATION
  WHERE  booking_id = v_bk_wait3;

  DBMS_OUTPUT.PUT_LINE('R9: AFTER CANCEL - booking '||v_bk_wait1||
                       ' -> status='||v_status1||', pos='||v_pos1);
  DBMS_OUTPUT.PUT_LINE('R9: AFTER CANCEL - booking '||v_bk_wait3||
                       ' -> status='||v_status3||', pos='||v_pos3);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R9: UNEXPECTED ERROR -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R10: cancel_ticket - NULL booking id (ERROR: ORA-20063)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R10: cancel_ticket - NULL booking id (ERROR: ORA-20063)
PROMPT ============================================================
BEGIN
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => NULL);
  DBMS_OUTPUT.PUT_LINE('R10: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R10: EXPECTED ERROR (NULL booking id) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R11: cancel_ticket - missing booking (ERROR: ORA-20064)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R11: cancel_ticket - missing booking (ERROR: ORA-20064)
PROMPT ============================================================
BEGIN
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => 999999);
  DBMS_OUTPUT.PUT_LINE('R11: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R11: EXPECTED ERROR (booking not found) -> '||SQLERRM);
END;
/

ROLLBACK;
-------------------------------------------------------------------------------
-- R12: cancel_ticket - already CANCELLED (ERROR: ORA-20065)
-------------------------------------------------------------------------------
PROMPT ============================================================
PROMPT R12: cancel_ticket - already CANCELLED (ERROR: ORA-20065)
PROMPT ============================================================
DECLARE
  v_passenger_id      NUMBER;
  v_booking_id        NUMBER;
  v_final_status      VARCHAR2(20);
  v_waitlist_position NUMBER;
BEGIN
  SELECT MIN(passenger_id)
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER;

  -- create a CONFIRMED booking
  TRAIN_DATA.pkg_reservation_mgmt.book_ticket(
    p_passenger_id      => v_passenger_id,
    p_train_number      => 'T101',
    p_travel_date       => TRUNC(SYSDATE)+1,
    p_seat_class        => 'ECON',
    p_booking_id        => v_booking_id,
    p_final_status      => v_final_status,
    p_waitlist_position => v_waitlist_position
  );

  -- first cancel (OK)
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => v_booking_id);

  -- second cancel should raise ORA-20065
  TRAIN_DATA.pkg_reservation_mgmt.cancel_ticket(p_booking_id => v_booking_id);
  DBMS_OUTPUT.PUT_LINE('R12: ERROR - this should NOT be printed');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('R12: EXPECTED ERROR (already cancelled) -> '||SQLERRM);
END;
/

ROLLBACK;

