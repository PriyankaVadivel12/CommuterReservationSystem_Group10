/******************************************************************
 *  PACKAGE 2: PKG_TRAIN_MGMT
 *
 *  Purpose:
 *    - Compute availability and waitlist information for a train
 *      on a specific travel date and seat class.
 *
 *  Responsibilities:
 *    - Validate input parameters (train number, travel date, seat class)
 *    - Validate seat class (FC / ECON)   -- Business / Economy
 *    - Validate train number exists and has correct format
 *    - Verify train is in service on that day of week
 *    - Enforce booking window (today .. today+7) for status checks
 *    - Count CONFIRMED and WAITLISTED reservations
 *    - Return:
 *        * total seats for that class
 *        * confirmed count
 *        * waitlisted count
 *        * available seats (total - confirmed, never < 0)
 *        * remaining waitlist slots (MAX_WAITLIST_PER_CLASS - waitlisted)
 *
 *  Error codes used (data / input validations – no raw Oracle errors):
 *    -20020 : Invalid seat class (must be FC or ECON)
 *    -20021 : Train not in service on given date
 *    -20022 : Invalid train number (does not exist in CRS_TRAIN_INFO)
 *    -20023 : Train number cannot be NULL/empty
 *    -20024 : Travel date cannot be NULL
 *    -20025 : Travel date is in the past
 *    -20026 : Travel date is outside booking window (today .. +7 days)
 *    -20027 : No schedule row for computed day-of-week
 *    -20028 : Invalid train number format (must look like T101, T202, etc.)
 *
 *  Business rule mapping:
 *    - “Business” class   -> stored as FC
 *    - “Economy” class    -> stored as ECON
 *    - 40 seats per class + 5 waitlist per class, per train, per date
 *    - Only one week advance booking allowed
 ******************************************************************/

------------------------------------------------------------
-- PACKAGE SPEC
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_train_mgmt AS

  ----------------------------------------------------------------
  -- PROCEDURE: get_availability
  --
  -- Parameters:
  --   p_train_number  IN  train number (e.g. 'T101')
  --   p_travel_date   IN  date of travel (NOT NULL)
  --   p_seat_class    IN  'FC' or 'ECON' (Business/Economy)
  --
  --   p_total_seats   OUT total seats for this class
  --   p_confirmed     OUT # of CONFIRMED reservations
  --   p_waitlisted    OUT # of WAITLISTED reservations
  --   p_available     OUT remaining seats (total - confirmed, never < 0)
  --   p_waitlist_left OUT remaining waitlist capacity
  --                     (MAX_WAITLIST_PER_CLASS - waitlisted, never < 0)
  ----------------------------------------------------------------
  PROCEDURE get_availability (
    p_train_number   IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date    IN  DATE,
    p_seat_class     IN  CRS_RESERVATION.seat_class%TYPE,
    p_total_seats    OUT NUMBER,
    p_confirmed      OUT NUMBER,
    p_waitlisted     OUT NUMBER,
    p_available      OUT NUMBER,
    p_waitlist_left  OUT NUMBER
  );

END pkg_train_mgmt;
/
SHOW ERRORS PACKAGE pkg_train_mgmt;
 

------------------------------------------------------------
-- PACKAGE BODY
------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_train_mgmt AS

  ----------------------------------------------------------------
  -- Package-level constants
  ----------------------------------------------------------------
  c_max_waitlist_per_class CONSTANT PLS_INTEGER := 5;

  ----------------------------------------------------------------
  -- get_availability
  ----------------------------------------------------------------
  PROCEDURE get_availability (
    p_train_number   IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date    IN  DATE,
    p_seat_class     IN  CRS_RESERVATION.seat_class%TYPE,
    p_total_seats    OUT NUMBER,
    p_confirmed      OUT NUMBER,
    p_waitlisted     OUT NUMBER,
    p_available      OUT NUMBER,
    p_waitlist_left  OUT NUMBER
  ) IS
    v_train_id        CRS_TRAIN_INFO.train_id%TYPE;
    v_fc_total        CRS_TRAIN_INFO.total_fc_seats%TYPE;
    v_econ_total      CRS_TRAIN_INFO.total_econ_seats%TYPE;
    v_day_code        VARCHAR2(10);
    v_sch_id          CRS_DAY_SCHEDULE.sch_id%TYPE;
    v_exists          NUMBER;
    v_today           DATE := TRUNC(SYSDATE);
    v_train_no_clean  CRS_TRAIN_INFO.train_number%TYPE;
    -- Seat class normalized to uppercase, wide enough to avoid ORA-06502
    v_seat_class_norm VARCHAR2(20);
  BEGIN
    ----------------------------------------------------------
    -- 0. Basic input validation (required fields)
    ----------------------------------------------------------
    v_train_no_clean := TRIM(p_train_number);

    IF v_train_no_clean IS NULL THEN
      RAISE_APPLICATION_ERROR(
        -20023,
        'Train number cannot be NULL or empty.'
      );
    END IF;

    IF p_travel_date IS NULL THEN
      RAISE_APPLICATION_ERROR(
        -20024,
        'Travel date cannot be NULL.'
      );
    END IF;

    IF TRUNC(p_travel_date) < v_today THEN
      RAISE_APPLICATION_ERROR(
        -20025,
        'Travel date is in the past. Availability is only for current/future dates.'
      );
    END IF;

    IF TRUNC(p_travel_date) > v_today + 7 THEN
      -- Mirror the "one week advance booking" rule at status level
      RAISE_APPLICATION_ERROR(
        -20026,
        'Travel date is outside allowed booking window (today .. +7 days).'
      );
    END IF;

    ----------------------------------------------------------
    -- 1. Validate train number format (T + digits)
    --    Catches “just numbers” or random strings up front.
    ----------------------------------------------------------
    IF NOT REGEXP_LIKE(v_train_no_clean, '^T[0-9]+$') THEN
      RAISE_APPLICATION_ERROR(
        -20028,
        'Invalid train number format. Expected like T101, T202, etc.'
      );
    END IF;

    ----------------------------------------------------------
    -- 2. Normalize / validate seat class
    --    Accepts FC/ECON case-insensitively, rejects others.
    ----------------------------------------------------------
    v_seat_class_norm := UPPER(p_seat_class);

    IF v_seat_class_norm NOT IN ('FC','ECON') THEN
      RAISE_APPLICATION_ERROR(-20020, 'Invalid seat class. Use FC or ECON.');
    END IF;

    ----------------------------------------------------------
    -- 3. Get train basic info (id + seat counts)
    --    If this fails, train number is invalid.
    ----------------------------------------------------------
    BEGIN
      SELECT train_id, total_fc_seats, total_econ_seats
      INTO   v_train_id, v_fc_total, v_econ_total
      FROM   CRS_TRAIN_INFO
      WHERE  train_number = v_train_no_clean;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20022,
          'Invalid train number: ' || v_train_no_clean
        );
    END;

    IF v_seat_class_norm = 'FC' THEN
      p_total_seats := v_fc_total;
    ELSE
      p_total_seats := v_econ_total;
    END IF;

    ----------------------------------------------------------
    -- 4. Determine day-of-week and verify train is in service
    ----------------------------------------------------------
    v_day_code := UPPER(
                    TO_CHAR(
                      TRUNC(p_travel_date),
                      'DY',
                      'NLS_DATE_LANGUAGE=ENGLISH'
                    )
                  );

    BEGIN
      SELECT sch_id
      INTO   v_sch_id
      FROM   CRS_DAY_SCHEDULE
      WHERE  day_of_week = v_day_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20027,
          'No schedule row for day-of-week "'||v_day_code||'" in CRS_DAY_SCHEDULE.'
        );
    END;

    SELECT COUNT(*)
    INTO   v_exists
    FROM   CRS_TRAIN_SCHEDULE
    WHERE  train_id      = v_train_id
    AND    sch_id        = v_sch_id
    AND    is_in_service = 'Y';

    IF v_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20021, 'Train not in service on given date.');
    END IF;

    ----------------------------------------------------------
    -- 5. Count CONFIRMED and WAITLISTED reservations
    ----------------------------------------------------------
    SELECT
      COUNT(CASE WHEN seat_status = 'CONFIRMED'  THEN 1 END),
      COUNT(CASE WHEN seat_status = 'WAITLISTED' THEN 1 END)
    INTO   p_confirmed,
           p_waitlisted
    FROM   CRS_RESERVATION
    WHERE  train_id    = v_train_id
    AND    travel_date = TRUNC(p_travel_date)
    AND    seat_class  = v_seat_class_norm;

    ----------------------------------------------------------
    -- 6. Compute availability / remaining waitlist capacity
    ----------------------------------------------------------
    p_available     := GREATEST(p_total_seats - p_confirmed, 0);
    p_waitlist_left := GREATEST(c_max_waitlist_per_class - p_waitlisted, 0);

  END get_availability;

END pkg_train_mgmt;
/
SHOW ERRORS PACKAGE BODY pkg_train_mgmt;
