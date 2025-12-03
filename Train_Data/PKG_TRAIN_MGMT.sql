/******************************************************************
 *  PACKAGE 2: PKG_TRAIN_MGMT
 *
 *  Responsibilities:
 *    1) Read-only train status:
 *       - get_availability(train#, date, class)
 *       - validates inputs and returns capacity & waitlist info
 *
 *    2) Train master data management:
 *       - create_train(...)          : insert new train with validation
 *       - update_train(...)          : update existing train
 *       - upsert_train_schedule(...) : maintain CRS_TRAIN_SCHEDULE
 *
 *  Error codes used (train status + admin):
 *    -20020 : Invalid seat class (must be FC or ECON)
 *    -20021 : Train not in service on given date
 *    -20022 : Invalid train number (not found in CRS_TRAIN_INFO)
 *    -20023 : Train number cannot be NULL or empty
 *    -20024 : Travel date cannot be NULL
 *    -20025 : Travel date is in the past
 *    -20026 : Travel date is outside booking window (today .. +7 days)
 *    -20027 : CRS_DAY_SCHEDULE has no row for computed day-of-week
 *    -20028 : Invalid train number format (expects T + digits)
 *    -20029 : Seat class cannot be NULL or empty
 *
 *    -20040 : Source station cannot be NULL
 *    -20041 : Destination station cannot be NULL
 *    -20042 : Source and destination stations cannot be the same
 *    -20043 : total_fc_seats must be > 0
 *    -20044 : total_econ_seats must be > 0
 *    -20045 : fc_seat_fare cannot be negative
 *    -20046 : econ_seat_fare cannot be negative
 *    -20047 : Train number already exists (on create_train)
 *    -20048 : Train not found for update (update_train)
 *    -20049 : Invalid day_of_week (no matching CRS_DAY_SCHEDULE row)
 *    -20050 : Invalid is_in_service flag (must be Y or N)
 ******************************************************************/

------------------------------------------------------------
-- PACKAGE SPEC
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_train_mgmt AS

  ----------------------------------------------------------------
  -- 1. PROCEDURE: get_availability
  --
  -- Parameters:
  --   p_train_number  IN  train number (e.g. 'T101')
  --   p_travel_date   IN  date of travel (NOT NULL)
  --   p_seat_class    IN  'FC' or 'ECON'
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

  ----------------------------------------------------------------
  -- 2. PROCEDURE: create_train
  --
  -- Creates a new train in CRS_TRAIN_INFO with full validation.
  -- Generates train_id internally (MAX(train_id)+1).
  ----------------------------------------------------------------
  PROCEDURE create_train (
    p_train_number     IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_source_station   IN  CRS_TRAIN_INFO.source_station%TYPE,
    p_dest_station     IN  CRS_TRAIN_INFO.dest_station%TYPE,
    p_total_fc_seats   IN  CRS_TRAIN_INFO.total_fc_seats%TYPE,
    p_total_econ_seats IN  CRS_TRAIN_INFO.total_econ_seats%TYPE,
    p_fc_seat_fare     IN  CRS_TRAIN_INFO.fc_seat_fare%TYPE,
    p_econ_seat_fare   IN  CRS_TRAIN_INFO.econ_seat_fare%TYPE,
    p_train_id         OUT CRS_TRAIN_INFO.train_id%TYPE
  );

  ----------------------------------------------------------------
  -- 3. PROCEDURE: update_train
  --
  -- Updates an existing train in CRS_TRAIN_INFO by train_number.
  ----------------------------------------------------------------
  PROCEDURE update_train (
    p_train_number     IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_source_station   IN  CRS_TRAIN_INFO.source_station%TYPE,
    p_dest_station     IN  CRS_TRAIN_INFO.dest_station%TYPE,
    p_total_fc_seats   IN  CRS_TRAIN_INFO.total_fc_seats%TYPE,
    p_total_econ_seats IN  CRS_TRAIN_INFO.total_econ_seats%TYPE,
    p_fc_seat_fare     IN  CRS_TRAIN_INFO.fc_seat_fare%TYPE,
    p_econ_seat_fare   IN  CRS_TRAIN_INFO.econ_seat_fare%TYPE
  );

  ----------------------------------------------------------------
  -- 4. PROCEDURE: upsert_train_schedule
  --
  -- Ensures CRS_TRAIN_SCHEDULE has a row for (train, day_of_week),
  -- and sets is_in_service = 'Y'/'N'. Creates row if missing.
  --
  -- Example:
  --   upsert_train_schedule('T101', 'MON', 'Y');
  ----------------------------------------------------------------
  PROCEDURE upsert_train_schedule (
    p_train_number  IN CRS_TRAIN_INFO.train_number%TYPE,
    p_day_of_week   IN CRS_DAY_SCHEDULE.day_of_week%TYPE,
    p_is_in_service IN CRS_TRAIN_SCHEDULE.is_in_service%TYPE
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
  -- Local helper: normalize and validate train number
  --  - trims
  --  - checks NOT NULL (ORA-20023)
  --  - checks format ^T[0-9]+$ (ORA-20028)
  ----------------------------------------------------------------
  FUNCTION normalize_train_number (
    p_train_number IN CRS_TRAIN_INFO.train_number%TYPE
  ) RETURN CRS_TRAIN_INFO.train_number%TYPE IS
    v_train_no_clean CRS_TRAIN_INFO.train_number%TYPE;
  BEGIN
    v_train_no_clean := TRIM(p_train_number);

    IF v_train_no_clean IS NULL THEN
      RAISE_APPLICATION_ERROR(-20023, 'Train number cannot be NULL or empty.');
    END IF;

    IF NOT REGEXP_LIKE(v_train_no_clean, '^T[0-9]+$') THEN
      RAISE_APPLICATION_ERROR(
        -20028,
        'Invalid train number format. Expected like T101, T202, etc.'
      );
    END IF;

    RETURN v_train_no_clean;
  END normalize_train_number;

  ----------------------------------------------------------------
  -- Local helper: normalize and validate seat class
  --  - uppercases
  --  - must be FC / ECON (ORA-20020)
  --  - NULL / empty -> ORA-20029
  ----------------------------------------------------------------
  FUNCTION normalize_seat_class (
    p_seat_class IN CRS_RESERVATION.seat_class%TYPE
  ) RETURN VARCHAR2 IS
    v_seat_class_norm VARCHAR2(20);
  BEGIN
    v_seat_class_norm := UPPER(TRIM(p_seat_class));

    IF v_seat_class_norm IS NULL THEN
      RAISE_APPLICATION_ERROR(
        -20029,
        'Seat class cannot be NULL or empty. Use FC or ECON.'
      );
    ELSIF v_seat_class_norm NOT IN ('FC','ECON') THEN
      RAISE_APPLICATION_ERROR(-20020, 'Invalid seat class. Use FC or ECON.');
    END IF;

    RETURN v_seat_class_norm;
  END normalize_seat_class;

  ----------------------------------------------------------------
  -- Local helper: validate core train attributes (no DB lookups)
  ----------------------------------------------------------------
  PROCEDURE validate_train_attributes (
    p_source_station   IN CRS_TRAIN_INFO.source_station%TYPE,
    p_dest_station     IN CRS_TRAIN_INFO.dest_station%TYPE,
    p_total_fc_seats   IN CRS_TRAIN_INFO.total_fc_seats%TYPE,
    p_total_econ_seats IN CRS_TRAIN_INFO.total_econ_seats%TYPE,
    p_fc_seat_fare     IN CRS_TRAIN_INFO.fc_seat_fare%TYPE,
    p_econ_seat_fare   IN CRS_TRAIN_INFO.econ_seat_fare%TYPE
  ) IS
    v_src VARCHAR2(100) := TRIM(p_source_station);
    v_dst VARCHAR2(100) := TRIM(p_dest_station);
  BEGIN
    IF v_src IS NULL THEN
      RAISE_APPLICATION_ERROR(-20040, 'Source station cannot be NULL.');
    END IF;

    IF v_dst IS NULL THEN
      RAISE_APPLICATION_ERROR(-20041, 'Destination station cannot be NULL.');
    END IF;

    IF UPPER(v_src) = UPPER(v_dst) THEN
      RAISE_APPLICATION_ERROR(
        -20042,
        'Source and destination stations cannot be the same.'
      );
    END IF;

    IF NVL(p_total_fc_seats, 0) <= 0 THEN
      RAISE_APPLICATION_ERROR(
        -20043,
        'Total first-class seats must be > 0.'
      );
    END IF;

    IF NVL(p_total_econ_seats, 0) <= 0 THEN
      RAISE_APPLICATION_ERROR(
        -20044,
        'Total economy seats must be > 0.'
      );
    END IF;

    IF NVL(p_fc_seat_fare, 0) < 0 THEN
      RAISE_APPLICATION_ERROR(
        -20045,
        'First-class seat fare cannot be negative.'
      );
    END IF;

    IF NVL(p_econ_seat_fare, 0) < 0 THEN
      RAISE_APPLICATION_ERROR(
        -20046,
        'Economy seat fare cannot be negative.'
      );
    END IF;
  END validate_train_attributes;

  ----------------------------------------------------------------
  -- 1) get_availability
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
    v_seat_class_norm VARCHAR2(20);
  BEGIN
    ----------------------------------------------------------
    -- 0. Basic input validation (travel date & window)
    ----------------------------------------------------------
    v_train_no_clean := normalize_train_number(p_train_number);

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
      RAISE_APPLICATION_ERROR(
        -20026,
        'Travel date is outside allowed booking window (today .. +7 days).'
      );
    END IF;

    v_seat_class_norm := normalize_seat_class(p_seat_class);

    ----------------------------------------------------------
    -- 1. Get train basic info (id + seat counts)
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
    -- 2. Determine day-of-week and verify train is in service
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
    -- 3. Count CONFIRMED and WAITLISTED reservations
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
    -- 4. Compute availability / remaining waitlist capacity
    ----------------------------------------------------------
    p_available     := GREATEST(p_total_seats - p_confirmed, 0);
    p_waitlist_left := GREATEST(c_max_waitlist_per_class - p_waitlisted, 0);
  END get_availability;

  ----------------------------------------------------------------
  -- 2) create_train
  ----------------------------------------------------------------
  PROCEDURE create_train (
    p_train_number     IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_source_station   IN  CRS_TRAIN_INFO.source_station%TYPE,
    p_dest_station     IN  CRS_TRAIN_INFO.dest_station%TYPE,
    p_total_fc_seats   IN  CRS_TRAIN_INFO.total_fc_seats%TYPE,
    p_total_econ_seats IN  CRS_TRAIN_INFO.total_econ_seats%TYPE,
    p_fc_seat_fare     IN  CRS_TRAIN_INFO.fc_seat_fare%TYPE,
    p_econ_seat_fare   IN  CRS_TRAIN_INFO.econ_seat_fare%TYPE,
    p_train_id         OUT CRS_TRAIN_INFO.train_id%TYPE
  ) IS
    v_train_no_clean CRS_TRAIN_INFO.train_number%TYPE;
    v_exists         NUMBER;
  BEGIN
    -- 1. Validate and normalize train number + attributes
    v_train_no_clean := normalize_train_number(p_train_number);

    validate_train_attributes(
      p_source_station   => p_source_station,
      p_dest_station     => p_dest_station,
      p_total_fc_seats   => p_total_fc_seats,
      p_total_econ_seats => p_total_econ_seats,
      p_fc_seat_fare     => p_fc_seat_fare,
      p_econ_seat_fare   => p_econ_seat_fare
    );

    -- 2. Ensure train number does not already exist
    SELECT COUNT(*)
    INTO   v_exists
    FROM   CRS_TRAIN_INFO
    WHERE  train_number = v_train_no_clean;

    IF v_exists > 0 THEN
      RAISE_APPLICATION_ERROR(
        -20047,
        'Train number already exists: '||v_train_no_clean
      );
    END IF;

    -- 3. Generate new train_id using MAX+1 (sufficient for assignment)
    SELECT NVL(MAX(train_id), 0) + 1
    INTO   p_train_id
    FROM   CRS_TRAIN_INFO;

    -- 4. Insert
    INSERT INTO CRS_TRAIN_INFO (
      train_id,
      train_number,
      source_station,
      dest_station,
      total_fc_seats,
      total_econ_seats,
      fc_seat_fare,
      econ_seat_fare
    ) VALUES (
      p_train_id,
      v_train_no_clean,
      TRIM(p_source_station),
      TRIM(p_dest_station),
      p_total_fc_seats,
      p_total_econ_seats,
      p_fc_seat_fare,
      p_econ_seat_fare
    );
  END create_train;

  ----------------------------------------------------------------
  -- 3) update_train
  ----------------------------------------------------------------
  PROCEDURE update_train (
    p_train_number     IN  CRS_TRAIN_INFO.train_number%TYPE,
    p_source_station   IN  CRS_TRAIN_INFO.source_station%TYPE,
    p_dest_station     IN  CRS_TRAIN_INFO.dest_station%TYPE,
    p_total_fc_seats   IN  CRS_TRAIN_INFO.total_fc_seats%TYPE,
    p_total_econ_seats IN  CRS_TRAIN_INFO.total_econ_seats%TYPE,
    p_fc_seat_fare     IN  CRS_TRAIN_INFO.fc_seat_fare%TYPE,
    p_econ_seat_fare   IN  CRS_TRAIN_INFO.econ_seat_fare%TYPE
  ) IS
    v_train_no_clean CRS_TRAIN_INFO.train_number%TYPE;
    v_train_id       CRS_TRAIN_INFO.train_id%TYPE;
  BEGIN
    -- 1. Validate and normalize
    v_train_no_clean := normalize_train_number(p_train_number);

    validate_train_attributes(
      p_source_station   => p_source_station,
      p_dest_station     => p_dest_station,
      p_total_fc_seats   => p_total_fc_seats,
      p_total_econ_seats => p_total_econ_seats,
      p_fc_seat_fare     => p_fc_seat_fare,
      p_econ_seat_fare   => p_econ_seat_fare
    );

    -- 2. Ensure train exists
    BEGIN
      SELECT train_id
      INTO   v_train_id
      FROM   CRS_TRAIN_INFO
      WHERE  train_number = v_train_no_clean;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20048,
          'Train not found for update: '||v_train_no_clean
        );
    END;

    -- 3. Update row
    UPDATE CRS_TRAIN_INFO
    SET source_station   = TRIM(p_source_station),
        dest_station     = TRIM(p_dest_station),
        total_fc_seats   = p_total_fc_seats,
        total_econ_seats = p_total_econ_seats,
        fc_seat_fare     = p_fc_seat_fare,
        econ_seat_fare   = p_econ_seat_fare
    WHERE train_id = v_train_id;
  END update_train;

  ----------------------------------------------------------------
  -- 4) upsert_train_schedule
  ----------------------------------------------------------------
  PROCEDURE upsert_train_schedule (
    p_train_number  IN CRS_TRAIN_INFO.train_number%TYPE,
    p_day_of_week   IN CRS_DAY_SCHEDULE.day_of_week%TYPE,
    p_is_in_service IN CRS_TRAIN_SCHEDULE.is_in_service%TYPE
  ) IS
    v_train_no_clean CRS_TRAIN_INFO.train_number%TYPE;
    v_train_id       CRS_TRAIN_INFO.train_id%TYPE;
    v_day_code       VARCHAR2(10);
    v_sch_id         CRS_DAY_SCHEDULE.sch_id%TYPE;
    v_is_flag        VARCHAR2(1);
    v_exists         NUMBER;
    v_new_tsch_id    CRS_TRAIN_SCHEDULE.tsch_id%TYPE;
  BEGIN
    -- 1. Normalize train number and resolve to train_id
    v_train_no_clean := normalize_train_number(p_train_number);

    BEGIN
      SELECT train_id
      INTO   v_train_id
      FROM   CRS_TRAIN_INFO
      WHERE  train_number = v_train_no_clean;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20022,
          'Invalid train number: ' || v_train_no_clean
        );
    END;

    -- 2. Normalize day_of_week (use first 3 chars, uppercased)
    v_day_code := UPPER(SUBSTR(TRIM(p_day_of_week), 1, 3));

    BEGIN
      SELECT sch_id
      INTO   v_sch_id
      FROM   CRS_DAY_SCHEDULE
      WHERE  day_of_week = v_day_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20049,
          'Invalid day_of_week: '||TRIM(p_day_of_week)||
          '. No matching CRS_DAY_SCHEDULE row.'
        );
    END;

    -- 3. Normalize is_in_service flag
    v_is_flag := UPPER(TRIM(p_is_in_service));

    IF v_is_flag NOT IN ('Y','N') THEN
      RAISE_APPLICATION_ERROR(
        -20050,
        'Invalid is_in_service flag. Allowed values: Y or N.'
      );
    END IF;

    -- 4. UPSERT into CRS_TRAIN_SCHEDULE
    SELECT COUNT(*)
    INTO   v_exists
    FROM   CRS_TRAIN_SCHEDULE
    WHERE  train_id = v_train_id
    AND    sch_id   = v_sch_id;

    IF v_exists > 0 THEN
      -- UPDATE existing row
      UPDATE CRS_TRAIN_SCHEDULE
      SET is_in_service = v_is_flag
      WHERE train_id = v_train_id
      AND   sch_id   = v_sch_id;
    ELSE
      -- INSERT new row (compute tsch_id as MAX+1)
      SELECT NVL(MAX(tsch_id), 0) + 1
      INTO   v_new_tsch_id
      FROM   CRS_TRAIN_SCHEDULE;

      INSERT INTO CRS_TRAIN_SCHEDULE (
        tsch_id,
        sch_id,
        train_id,
        is_in_service
      ) VALUES (
        v_new_tsch_id,
        v_sch_id,
        v_train_id,
        v_is_flag
      );
    END IF;
  END upsert_train_schedule;

END pkg_train_mgmt;
/
SHOW ERRORS PACKAGE BODY pkg_train_mgmt;
