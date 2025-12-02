/******************************************************************
 *  PACKAGE 2: PKG_TRAIN_MGMT
 *
 *  Purpose:
 *    - Compute availability and waitlist information for a train
 *      on a specific travel date and seat class.
 *
 *  Responsibilities:
 *    - Validate train number exists
 *    - Validate seat class (FC / ECON)
 *    - Verify train is in service on that day of week
 *    - Count CONFIRMED and WAITLISTED reservations
 *    - Return:
 *        * total seats for that class
 *        * confirmed count
 *        * waitlisted count
 *        * available seats (total - confirmed)
 *        * remaining waitlist slots (5 - waitlisted)
 *
 *  Error codes:
 *    -20020 : Invalid seat class (must be FC or ECON)
 *    -20021 : Train not in service on given date
 *    -20022 : Invalid train number or day mapping
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
  --   p_travel_date   IN  date of travel
  --   p_seat_class    IN  'FC' or 'ECON'
  --
  --   p_total_seats   OUT total seats for this class
  --   p_confirmed     OUT # of CONFIRMED reservations
  --   p_waitlisted    OUT # of WAITLISTED reservations
  --   p_available     OUT remaining seats (total - confirmed)
  --   p_waitlist_left OUT remaining waitlist capacity (5 - waitlisted)
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
    v_train_id    CRS_TRAIN_INFO.train_id%TYPE;
    v_fc_total    CRS_TRAIN_INFO.total_fc_seats%TYPE;
    v_econ_total  CRS_TRAIN_INFO.total_econ_seats%TYPE;
    v_day_code    VARCHAR2(10);
    v_sch_id      CRS_DAY_SCHEDULE.sch_id%TYPE;
    v_exists      NUMBER;
  BEGIN
    ----------------------------------------------------------
    -- 1. Validate seat class
    ----------------------------------------------------------
    IF p_seat_class NOT IN ('FC','ECON') THEN
      RAISE_APPLICATION_ERROR(-20020, 'Invalid seat class. Use FC or ECON.');
    END IF;

    ----------------------------------------------------------
    -- 2. Get train basic info (id + seat counts)
    ----------------------------------------------------------
    SELECT train_id, total_fc_seats, total_econ_seats
    INTO   v_train_id, v_fc_total, v_econ_total
    FROM   CRS_TRAIN_INFO
    WHERE  train_number = p_train_number;

    IF p_seat_class = 'FC' THEN
      p_total_seats := v_fc_total;
    ELSE
      p_total_seats := v_econ_total;
    END IF;

    ----------------------------------------------------------
    -- 3. Determine day-of-week and verify train is in service
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
      RAISE_APPLICATION_ERROR(-20021, 'Train not in service on given date.');
    END IF;

    ----------------------------------------------------------
    -- 4. Count CONFIRMED and WAITLISTED reservations
    ----------------------------------------------------------
    SELECT COUNT(*)
    INTO   p_confirmed
    FROM   CRS_RESERVATION
    WHERE  train_id    = v_train_id
    AND    travel_date = TRUNC(p_travel_date)
    AND    seat_class  = p_seat_class
    AND    seat_status = 'CONFIRMED';

    SELECT COUNT(*)
    INTO   p_waitlisted
    FROM   CRS_RESERVATION
    WHERE  train_id    = v_train_id
    AND    travel_date = TRUNC(p_travel_date)
    AND    seat_class  = p_seat_class
    AND    seat_status = 'WAITLISTED';

    ----------------------------------------------------------
    -- 5. Compute availability / remaining waitlist capacity
    ----------------------------------------------------------
    p_available     := p_total_seats - p_confirmed;
    p_waitlist_left := GREATEST(5 - p_waitlisted, 0);  -- per class

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(
        -20022,
        'Invalid train number or day mapping.'
      );
  END get_availability;

END pkg_train_mgmt;
/
SHOW ERRORS PACKAGE BODY pkg_train_mgmt;
