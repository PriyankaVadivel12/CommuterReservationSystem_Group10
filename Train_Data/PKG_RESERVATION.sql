
/******************************************************************
 *  PACKAGE 3: PKG_RESERVATION
 *
 *  Purpose:
 *    - Manage ticket bookings and cancellations.
 *
 *  Business Rules implemented:
 *    - Passenger must exist.
 *    - Train number must be valid.
 *    - Train must be in service on travel date.
 *    - Only 1-week advance booking allowed (no past dates).
 *    - Seat classes: FC / ECON only.
 *    - Max 40 CONFIRMED tickets per train/date/class.
 *    - Max 5 WAITLISTED tickets per train/date/class.
 *    - If seats full then waitlist; if waitlist also full → reject.
 *    - Cancellation:
 *        * Changes status to CANCELLED.
 *        * If cancelled ticket was CONFIRMED, promote first WAITLISTED.
 *        * Reorder waitlist positions after any change.
 *
 *  Error codes:
 *    -20030 : Cannot book for past dates
 *    -20031 : Only 1 week advance booking allowed
 *    -20032 : Invalid seat class (must be FC/ECON)
 *    -20033 : Train not in service on given date
 *    -20034 : No seats or waitlist available
 *    -20035 : Invalid passenger id or train number
 *    -20036 : Ticket already cancelled
 *    -20037 : Booking ID not found
 ******************************************************************/

------------------------------------------------------------
-- PACKAGE SPEC
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_reservation AS

  ----------------------------------------------------------------
  -- PROCEDURE: book_ticket
  --
  -- Input:
  --   p_passenger_id : existing passenger_id
  --   p_train_number : e.g. 'T101'
  --   p_travel_date  : desired travel date
  --   p_seat_class   : 'FC' or 'ECON'
  --
  -- Output:
  --   p_booking_id   : generated booking id
  --   p_seat_status  : 'CONFIRMED' or 'WAITLISTED'
  ----------------------------------------------------------------
  PROCEDURE book_ticket (
    p_passenger_id IN  CRS_PASSENGER.passenger_id%TYPE,
    p_train_number IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date  IN  DATE,
    p_seat_class   IN  CRS_RESERVATION.seat_class%TYPE,
    p_booking_id   OUT CRS_RESERVATION.booking_id%TYPE,
    p_seat_status  OUT CRS_RESERVATION.seat_status%TYPE
  );

  ----------------------------------------------------------------
  -- PROCEDURE: cancel_ticket
  --
  -- Input:
  --   p_booking_id : booking to cancel
  --
  -- Behaviour:
  --   - Marks record as CANCELLED (if not already).
  --   - If it was CONFIRMED, promotes first WAITLISTED ticket.
  --   - Reorders waitlist positions.
  ----------------------------------------------------------------
  PROCEDURE cancel_ticket (
    p_booking_id IN CRS_RESERVATION.booking_id%TYPE
  );

END pkg_reservation;
/
SHOW ERRORS PACKAGE pkg_reservation;



------------------------------------------------------------
-- PACKAGE BODY
------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_reservation AS

  ----------------------------------------------------------------
  -- Helper: check_booking_window
  -- Validates that travel_date is:
  --   - not in the past
  --   - not more than 7 days in the future
  ----------------------------------------------------------------
  PROCEDURE check_booking_window(p_travel_date IN DATE) IS
    v_today DATE := TRUNC(SYSDATE);
  BEGIN
    IF TRUNC(p_travel_date) < v_today THEN
      RAISE_APPLICATION_ERROR(-20030, 'Cannot book for past dates.');
    ELSIF TRUNC(p_travel_date) > v_today + 7 THEN
      RAISE_APPLICATION_ERROR(-20031, 'Only 1 week advance booking allowed.');
    END IF;
  END check_booking_window;



  ----------------------------------------------------------------
  -- Helper: reorder_waitlist
  -- Re-numbers waitlist positions sequentially starting from 1
  -- for the given train/date/class.
  ----------------------------------------------------------------
  PROCEDURE reorder_waitlist (
    p_train_id    IN CRS_RESERVATION.train_id%TYPE,
    p_travel_date IN CRS_RESERVATION.travel_date%TYPE,
    p_seat_class  IN CRS_RESERVATION.seat_class%TYPE
  ) IS
    CURSOR c_wait IS
      SELECT booking_id
      FROM   CRS_RESERVATION
      WHERE  train_id    = p_train_id
      AND    travel_date = p_travel_date
      AND    seat_class  = p_seat_class
      AND    seat_status = 'WAITLISTED'
      ORDER BY waitlist_position, booking_id;

    v_pos NUMBER := 0;
  BEGIN
    FOR r IN c_wait LOOP
      v_pos := v_pos + 1;
      UPDATE CRS_RESERVATION
      SET waitlist_position = v_pos
      WHERE booking_id = r.booking_id;
    END LOOP;
  END reorder_waitlist;



  ----------------------------------------------------------------
  -- book_ticket
  ----------------------------------------------------------------
  PROCEDURE book_ticket (
    p_passenger_id IN  CRS_PASSENGER.passenger_id%TYPE,
    p_train_number IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date  IN  DATE,
    p_seat_class   IN  CRS_RESERVATION.seat_class%TYPE,
    p_booking_id   OUT CRS_RESERVATION.booking_id%TYPE,
    p_seat_status  OUT CRS_RESERVATION.seat_status%TYPE
  ) IS
    v_train_id      CRS_TRAIN_INFO.train_id%TYPE;
    v_fc_total      CRS_TRAIN_INFO.total_fc_seats%TYPE;
    v_econ_total    CRS_TRAIN_INFO.total_econ_seats%TYPE;
    v_total_seats   NUMBER;
    v_confirmed     NUMBER;
    v_waitlisted    NUMBER;
    v_day_code      VARCHAR2(10);
    v_sch_id        CRS_DAY_SCHEDULE.sch_id%TYPE;
    v_exists        NUMBER;
    v_dummy         NUMBER;
    v_booking_date  DATE := TRUNC(SYSDATE);
  BEGIN
    ----------------------------------------------------------
    -- 1. Validate passenger exists
    ----------------------------------------------------------
    SELECT 1 INTO v_dummy
    FROM CRS_PASSENGER
    WHERE passenger_id = p_passenger_id;

    ----------------------------------------------------------
    -- 2. Validate seat class
    ----------------------------------------------------------
    IF p_seat_class NOT IN ('FC','ECON') THEN
      RAISE_APPLICATION_ERROR(-20032, 'Invalid seat class. Use FC or ECON.');
    END IF;

    ----------------------------------------------------------
    -- 3. Validate booking window (not past, <= 7 days)
    ----------------------------------------------------------
    check_booking_window(p_travel_date);

    ----------------------------------------------------------
    -- 4. Get train info (id + total seats per class)
    ----------------------------------------------------------
    SELECT train_id, total_fc_seats, total_econ_seats
    INTO   v_train_id, v_fc_total, v_econ_total
    FROM   CRS_TRAIN_INFO
    WHERE  train_number = p_train_number;

    IF p_seat_class = 'FC' THEN
      v_total_seats := v_fc_total;
    ELSE
      v_total_seats := v_econ_total;
    END IF;

    ----------------------------------------------------------
    -- 5. Ensure train is in service on that day
    ----------------------------------------------------------
    v_day_code := UPPER(
                    TO_CHAR(
                      TRUNC(p_travel_date),
                      'DY',
                      'NLS_DATE_LANGUAGE=ENGLISH'
                    )
                  );

    SELECT sch_id
    INTO   v_sch_id
    FROM   CRS_DAY_SCHEDULE
    WHERE  day_of_week = v_day_code;

    SELECT COUNT(*)
    INTO   v_exists
    FROM   CRS_TRAIN_SCHEDULE
    WHERE  train_id      = v_train_id
    AND    sch_id        = v_sch_id
    AND    is_in_service = 'Y';

    IF v_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20033, 'Train not in service on given date.');
    END IF;

    ----------------------------------------------------------
    -- 6. Count CONFIRMED and WAITLISTED for this trip/class
    ----------------------------------------------------------
    SELECT COUNT(*)
    INTO   v_confirmed
    FROM   CRS_RESERVATION
    WHERE  train_id    = v_train_id
    AND    travel_date = TRUNC(p_travel_date)
    AND    seat_class  = p_seat_class
    AND    seat_status = 'CONFIRMED';

    SELECT COUNT(*)
    INTO   v_waitlisted
    FROM   CRS_RESERVATION
    WHERE  train_id    = v_train_id
    AND    travel_date = TRUNC(p_travel_date)
    AND    seat_class  = p_seat_class
    AND    seat_status = 'WAITLISTED';

    ----------------------------------------------------------
    -- 7. Decide CONFIRMED vs WAITLISTED vs REJECT
    ----------------------------------------------------------
    IF v_confirmed < v_total_seats THEN
      -- CONFIRMED booking
      p_seat_status := 'CONFIRMED';
      p_booking_id  := seq_crs_reservation.NEXTVAL;

      INSERT INTO CRS_RESERVATION (
        booking_id, passenger_id, train_id,
        travel_date, booking_date,
        seat_class, seat_status, waitlist_position
      ) VALUES (
        p_booking_id, p_passenger_id, v_train_id,
        TRUNC(p_travel_date), v_booking_date,
        p_seat_class, p_seat_status, NULL
      );

    ELSIF v_waitlisted < 5 THEN
      -- WAITLISTED booking
      p_seat_status := 'WAITLISTED';
      p_booking_id  := seq_crs_reservation.NEXTVAL;

      INSERT INTO CRS_RESERVATION (
        booking_id, passenger_id, train_id,
        travel_date, booking_date,
        seat_class, seat_status, waitlist_position
      ) VALUES (
        p_booking_id, p_passenger_id, v_train_id,
        TRUNC(p_travel_date), v_booking_date,
        p_seat_class, p_seat_status, v_waitlisted + 1
      );

    ELSE
      -- No seats and no waitlist space
      RAISE_APPLICATION_ERROR(
        -20034,
        'No seats or waitlist available for this train/date/class.'
      );
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(
        -20035,
        'Invalid passenger id or train number.'
      );
  END book_ticket;



  ----------------------------------------------------------------
  -- cancel_ticket
  ----------------------------------------------------------------
  PROCEDURE cancel_ticket (
    p_booking_id IN CRS_RESERVATION.booking_id%TYPE
  ) IS
    v_train_id      CRS_RESERVATION.train_id%TYPE;
    v_travel_date   CRS_RESERVATION.travel_date%TYPE;
    v_seat_class    CRS_RESERVATION.seat_class%TYPE;
    v_seat_status   CRS_RESERVATION.seat_status%TYPE;
  BEGIN
    ----------------------------------------------------------
    -- 1. Fetch reservation row
    ----------------------------------------------------------
    SELECT train_id, travel_date, seat_class, seat_status
    INTO   v_train_id, v_travel_date, v_seat_class, v_seat_status
    FROM   CRS_RESERVATION
    WHERE  booking_id = p_booking_id;

    IF v_seat_status = 'CANCELLED' THEN
      RAISE_APPLICATION_ERROR(-20036, 'Ticket already cancelled.');
    END IF;

    ----------------------------------------------------------
    -- 2. Mark as CANCELLED
    ----------------------------------------------------------
    UPDATE CRS_RESERVATION
    SET seat_status       = 'CANCELLED',
        waitlist_position = NULL
    WHERE booking_id      = p_booking_id;

    ----------------------------------------------------------
    -- 3. If it was CONFIRMED, promote the first WAITLISTED
    ----------------------------------------------------------
    IF v_seat_status = 'CONFIRMED' THEN
      DECLARE
        v_wait_booking CRS_RESERVATION.booking_id%TYPE;
      BEGIN
        SELECT booking_id
        INTO   v_wait_booking
        FROM   (
          SELECT booking_id
          FROM   CRS_RESERVATION
          WHERE  train_id    = v_train_id
          AND    travel_date = v_travel_date
          AND    seat_class  = v_seat_class
          AND    seat_status = 'WAITLISTED'
          ORDER BY waitlist_position, booking_id
        )
        WHERE  ROWNUM = 1;

        -- Promote
        UPDATE CRS_RESERVATION
        SET seat_status       = 'CONFIRMED',
            waitlist_position = NULL
        WHERE booking_id      = v_wait_booking;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -- no waitlisted tickets to promote
      END;
    END IF;

    ----------------------------------------------------------
    -- 4. Reorder remaining waitlist positions
    ----------------------------------------------------------
    reorder_waitlist(v_train_id, v_travel_date, v_seat_class);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20037, 'Booking ID not found.');
  END cancel_ticket;

END pkg_reservation;
/
SHOW ERRORS PACKAGE BODY pkg_reservation;

