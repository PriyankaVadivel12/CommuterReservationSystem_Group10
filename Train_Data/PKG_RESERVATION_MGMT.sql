/******************************************************************
 *  PACKAGE 3: PKG_RESERVATION_MGMT
 *
 *  Responsibilities:
 *    - Booking tickets for existing passengers on existing trains
 *    - Enforcing capacity and waitlist rules using PKG_TRAIN_MGMT
 *    - Cancelling tickets and promoting waitlisted passengers
 *
 *  Tables involved:
 *    - CRS_PASSENGER
 *    - CRS_TRAIN_INFO
 *    - CRS_RESERVATION
 *
 *  Relies on:
 *    - PKG_TRAIN_MGMT.get_availability(...) for:
 *        * train# format and existence
 *        * valid service day / in-service check
 *        * booking window (today .. today+7)
 *        * seat class validation (FC / ECON)
 *
 *  Key business rules implemented:
 *    - Passenger must exist by passenger_id
 *    - Only one-week advance booking allowed (enforced by train pkg)
 *    - Two classes only: FC and ECON (enforced by train pkg)
 *    - Capacity per class: 40 seats, 5 waitlist (from train pkg / constants)
 *    - When seats are free -> CONFIRMED
 *    - When full but waitlist slots free -> WAITLISTED with position
 *    - When neither seats nor waitlist slots free -> error
 *    - Cancellation:
 *        * CONFIRMED -> CANCELLED, first WAITLISTED promoted
 *        * WAITLISTED -> CANCELLED, remaining waitlist positions compacted
 *
 *  Error codes used (reservation specific):
 *    -20060 : Passenger id cannot be NULL
 *    -20061 : Passenger not found in CRS_PASSENGER
 *    -20062 : No seats or waitlist capacity left for this train/date/class
 *    -20063 : Booking id cannot be NULL
 *    -20064 : Booking not found in CRS_RESERVATION
 *    -20065 : Booking already CANCELLED
 *
 *  NOTE:
 *    - Train-related errors (ORA-2002x) are raised by PKG_TRAIN_MGMT
 *      and propagated by book_ticket.
 ******************************************************************/

------------------------------------------------------------
-- PACKAGE SPEC
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_reservation_mgmt AS

  ----------------------------------------------------------------
  -- PROCEDURE: book_ticket
  --
  -- Parameters:
  --   p_passenger_id       IN  CRS_RESERVATION.passenger_id%TYPE
  --   p_train_number       IN  CRS_TRAIN_INFO.train_number%TYPE
  --   p_travel_date        IN  DATE
  --   p_seat_class         IN  CRS_RESERVATION.seat_class%TYPE
  --
  --   p_booking_id         OUT CRS_RESERVATION.booking_id%TYPE
  --   p_final_status       OUT CRS_RESERVATION.seat_status%TYPE
  --   p_waitlist_position  OUT CRS_RESERVATION.waitlist_position%TYPE
  --
  -- Behavior:
  --   1) Validates passenger, train, date and seat class
  --   2) Uses PKG_TRAIN_MGMT.get_availability to check capacity
  --   3) Inserts a new CRS_RESERVATION row:
  --        - seat_status       = CONFIRMED or WAITLISTED
  --        - waitlist_position = NULL (confirmed) or sequence (waitlisted)
  --   4) Returns booking_id, final status, and waitlist_position.
  --
  --   Errors (in addition to train errors):
  --     ORA-20060 : passenger id is NULL
  --     ORA-20061 : passenger not found
  --     ORA-20062 : no seats or waitlist capacity left
  ----------------------------------------------------------------
  PROCEDURE book_ticket (
    p_passenger_id       IN  CRS_RESERVATION.passenger_id%TYPE,
    p_train_number       IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date        IN  DATE,
    p_seat_class         IN  CRS_RESERVATION.seat_class%TYPE,
    p_booking_id         OUT CRS_RESERVATION.booking_id%TYPE,
    p_final_status       OUT CRS_RESERVATION.seat_status%TYPE,
    p_waitlist_position  OUT CRS_RESERVATION.waitlist_position%TYPE
  );

  ----------------------------------------------------------------
  -- PROCEDURE: cancel_ticket
  --
  -- Parameters:
  --   p_booking_id  IN  CRS_RESERVATION.booking_id%TYPE
  --
  -- Behavior:
  --   - If booking is CONFIRMED:
  --       1) Mark it CANCELLED (waitlist_position := NULL)
  --       2) Promote first WAITLISTED booking (same train/date/class)
  --          to CONFIRMED (clearing waitlist_position)
  --   - If booking is WAITLISTED:
  --       1) Mark it CANCELLED
  --       2) Decrement waitlist_position for all higher positions
  --
  --   Errors:
  --     ORA-20063 : booking id is NULL
  --     ORA-20064 : booking not found
  --     ORA-20065 : booking already CANCELLED
  ----------------------------------------------------------------
  PROCEDURE cancel_ticket (
    p_booking_id IN CRS_RESERVATION.booking_id%TYPE
  );

END pkg_reservation_mgmt;
/
SHOW ERRORS PACKAGE pkg_reservation_mgmt;


------------------------------------------------------------
-- PACKAGE BODY
------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_reservation_mgmt AS

  ----------------------------------------------------------------
  -- Local helper: check passenger exists
  ----------------------------------------------------------------
  PROCEDURE assert_valid_passenger (
    p_passenger_id IN CRS_RESERVATION.passenger_id%TYPE
  ) IS
    v_cnt NUMBER;
  BEGIN
    IF p_passenger_id IS NULL THEN
      RAISE_APPLICATION_ERROR(
        -20060,
        'Passenger id cannot be NULL.'
      );
    END IF;

    SELECT COUNT(*)
    INTO   v_cnt
    FROM   CRS_PASSENGER
    WHERE  passenger_id = p_passenger_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(
        -20061,
        'Passenger not found for id: '||p_passenger_id
      );
    END IF;
  END assert_valid_passenger;


  ----------------------------------------------------------------
  -- PROCEDURE: book_ticket
  ----------------------------------------------------------------
  PROCEDURE book_ticket (
    p_passenger_id       IN  CRS_RESERVATION.passenger_id%TYPE,
    p_train_number       IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date        IN  DATE,
    p_seat_class         IN  CRS_RESERVATION.seat_class%TYPE,
    p_booking_id         OUT CRS_RESERVATION.booking_id%TYPE,
    p_final_status       OUT CRS_RESERVATION.seat_status%TYPE,
    p_waitlist_position  OUT CRS_RESERVATION.waitlist_position%TYPE
  ) IS
    v_total_seats    NUMBER;
    v_confirmed      NUMBER;
    v_waitlisted     NUMBER;
    v_available      NUMBER;
    v_waitlist_left  NUMBER;

    v_train_id        CRS_TRAIN_INFO.train_id%TYPE;
    v_seat_class_norm VARCHAR2(20);

    v_next_booking_id   CRS_RESERVATION.booking_id%TYPE;
    v_next_waitlist_pos CRS_RESERVATION.waitlist_position%TYPE;
  BEGIN
    ----------------------------------------------------------
    -- 1. Passenger validation
    ----------------------------------------------------------
    assert_valid_passenger(p_passenger_id);

    ----------------------------------------------------------
    -- 2. Get availability via PKG_TRAIN_MGMT
    --    -> validates train#, travel date, seat class, window, service day
    ----------------------------------------------------------
    TRAIN_DATA.pkg_train_mgmt.get_availability(
      p_train_number   => p_train_number,
      p_travel_date    => p_travel_date,
      p_seat_class     => p_seat_class,
      p_total_seats    => v_total_seats,
      p_confirmed      => v_confirmed,
      p_waitlisted     => v_waitlisted,
      p_available      => v_available,
      p_waitlist_left  => v_waitlist_left
    );

    ----------------------------------------------------------
    -- 3. Resolve train_id and normalized seat class
    --    (train# and class already validated by get_availability)
    ----------------------------------------------------------
    SELECT train_id
    INTO   v_train_id
    FROM   CRS_TRAIN_INFO
    WHERE  train_number = TRIM(p_train_number);

    v_seat_class_norm := UPPER(TRIM(p_seat_class));

    ----------------------------------------------------------
    -- 4. Decide status: CONFIRMED vs WAITLISTED vs error
    ----------------------------------------------------------
    IF v_available > 0 THEN
      p_final_status      := 'CONFIRMED';
      p_waitlist_position := NULL;

    ELSIF v_available = 0 AND v_waitlist_left > 0 THEN
      p_final_status := 'WAITLISTED';

      SELECT NVL(MAX(waitlist_position), 0) + 1
      INTO   v_next_waitlist_pos
      FROM   CRS_RESERVATION
      WHERE  train_id    = v_train_id
      AND    travel_date = TRUNC(p_travel_date)
      AND    seat_class  = v_seat_class_norm
      AND    seat_status = 'WAITLISTED';

      p_waitlist_position := v_next_waitlist_pos;

    ELSE
      RAISE_APPLICATION_ERROR(
        -20062,
        'No seats or waitlist capacity left for train '||
        TRIM(p_train_number)||' on '||
        TO_CHAR(TRUNC(p_travel_date),'YYYY-MM-DD')||
        ' (class '||v_seat_class_norm||').'
      );
    END IF;

    ----------------------------------------------------------
    -- 5. Generate booking_id (simple MAX+1 approach)
    ----------------------------------------------------------
    SELECT NVL(MAX(booking_id), 0) + 1
    INTO   v_next_booking_id
    FROM   CRS_RESERVATION;

    p_booking_id := v_next_booking_id;

    ----------------------------------------------------------
    -- 6. Insert reservation row (force non-parallel DML)
    ----------------------------------------------------------
    INSERT /*+ NOPARALLEL */
      INTO CRS_RESERVATION (
        booking_id,
        passenger_id,
        train_id,
        travel_date,
        booking_date,
        seat_class,
        seat_status,
        waitlist_position
      ) VALUES (
        p_booking_id,
        p_passenger_id,
        v_train_id,
        TRUNC(p_travel_date),
        TRUNC(SYSDATE),
        v_seat_class_norm,
        p_final_status,
        p_waitlist_position
      );
  END book_ticket;


  ----------------------------------------------------------------
  -- PROCEDURE: cancel_ticket
  ----------------------------------------------------------------
  PROCEDURE cancel_ticket (
    p_booking_id IN CRS_RESERVATION.booking_id%TYPE
  ) IS
    v_train_id          CRS_RESERVATION.train_id%TYPE;
    v_travel_date       CRS_RESERVATION.travel_date%TYPE;
    v_seat_class        CRS_RESERVATION.seat_class%TYPE;
    v_seat_status       CRS_RESERVATION.seat_status%TYPE;
    v_waitlist_position CRS_RESERVATION.waitlist_position%TYPE;

    v_promote_booking_id CRS_RESERVATION.booking_id%TYPE;
    v_promote_position   CRS_RESERVATION.waitlist_position%TYPE;
  BEGIN
    ----------------------------------------------------------
    -- 1. Basic validation of booking_id
    ----------------------------------------------------------
    IF p_booking_id IS NULL THEN
      RAISE_APPLICATION_ERROR(
        -20063,
        'Booking id cannot be NULL.'
      );
    END IF;

    ----------------------------------------------------------
    -- 2. Fetch reservation row FOR UPDATE
    ----------------------------------------------------------
    BEGIN
      SELECT train_id,
             travel_date,
             seat_class,
             seat_status,
             waitlist_position
      INTO   v_train_id,
             v_travel_date,
             v_seat_class,
             v_seat_status,
             v_waitlist_position
      FROM   CRS_RESERVATION
      WHERE  booking_id = p_booking_id
      FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20064,
          'Booking not found for id: '||p_booking_id
        );
    END;

    IF v_seat_status = 'CANCELLED' THEN
      RAISE_APPLICATION_ERROR(
        -20065,
        'Booking '||p_booking_id||' is already CANCELLED.'
      );
    END IF;

    ----------------------------------------------------------
    -- 3. Handle CONFIRMED cancellation
    ----------------------------------------------------------
    IF v_seat_status = 'CONFIRMED' THEN
      -- a) cancel current booking
      UPDATE /*+ NOPARALLEL */
             CRS_RESERVATION
      SET    seat_status       = 'CANCELLED',
             waitlist_position = NULL
      WHERE  booking_id        = p_booking_id;

      -- b) promote first WAITLISTED (lowest position), if any
      BEGIN
        SELECT booking_id, waitlist_position
        INTO   v_promote_booking_id, v_promote_position
        FROM   CRS_RESERVATION
        WHERE  train_id    = v_train_id
        AND    travel_date = v_travel_date
        AND    seat_class  = v_seat_class
        AND    seat_status = 'WAITLISTED'
        AND    waitlist_position = (
                 SELECT MIN(waitlist_position)
                 FROM   CRS_RESERVATION
                 WHERE  train_id    = v_train_id
                 AND    travel_date = v_travel_date
                 AND    seat_class  = v_seat_class
                 AND    seat_status = 'WAITLISTED'
               );

        UPDATE /*+ NOPARALLEL */
               CRS_RESERVATION
        SET    seat_status       = 'CONFIRMED',
               waitlist_position = NULL
        WHERE  booking_id        = v_promote_booking_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- no waitlist to promote: nothing else to do
          NULL;
      END;

    ----------------------------------------------------------
    -- 4. Handle WAITLISTED cancellation
    ----------------------------------------------------------
    ELSIF v_seat_status = 'WAITLISTED' THEN
      -- a) cancel this waitlisted booking
      UPDATE /*+ NOPARALLEL */
             CRS_RESERVATION
      SET    seat_status       = 'CANCELLED',
             waitlist_position = NULL
      WHERE  booking_id        = p_booking_id;

      -- b) compact positions above the cancelled one
      IF v_waitlist_position IS NOT NULL THEN
        UPDATE /*+ NOPARALLEL */
               CRS_RESERVATION
        SET    waitlist_position = waitlist_position - 1
        WHERE  train_id          = v_train_id
        AND    travel_date       = v_travel_date
        AND    seat_class        = v_seat_class
        AND    seat_status       = 'WAITLISTED'
        AND    waitlist_position > v_waitlist_position;
      END IF;

    ----------------------------------------------------------
    -- 5. If some unexpected status, just mark CANCELLED
    --    (defensive, should not normally happen)
    ----------------------------------------------------------
    ELSE
      UPDATE /*+ NOPARALLEL */
             CRS_RESERVATION
      SET    seat_status       = 'CANCELLED',
             waitlist_position = NULL
      WHERE  booking_id        = p_booking_id;
    END IF;
  END cancel_ticket;

END pkg_reservation_mgmt;
/
SHOW ERRORS PACKAGE BODY pkg_reservation_mgmt;
