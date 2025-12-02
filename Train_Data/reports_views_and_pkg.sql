------------------------------------------------------------------
-- RUN AS: TRAIN_DATA
-- PURPOSE:
--   1) Create reporting/audit views
--   2) Create reporting package PKG_CRS_REPORTS (read-only)
------------------------------------------------------------------

------------------------------------------------------------------
-- VIEW 1: CRS_V_TRAIN_DAILY_LOAD
--  - Aggregated load per train / travel_date / seat_class
------------------------------------------------------------------
CREATE OR REPLACE VIEW CRS_V_TRAIN_DAILY_LOAD AS
SELECT
    r.travel_date,
    t.train_number,
    t.source_station,
    t.dest_station,
    r.seat_class,
    CASE
      WHEN r.seat_class = 'FC'   THEN t.total_fc_seats
      WHEN r.seat_class = 'ECON' THEN t.total_econ_seats
      ELSE NULL
    END AS total_seats,
    SUM(CASE WHEN r.seat_status = 'CONFIRMED' THEN 1 ELSE 0 END) AS confirmed_seats,
    SUM(CASE WHEN r.seat_status = 'WAITLISTED' THEN 1 ELSE 0 END) AS waitlisted_seats,
    SUM(CASE WHEN r.seat_status = 'CANCELLED'  THEN 1 ELSE 0 END) AS cancelled_seats,
    CASE
      WHEN r.seat_class = 'FC'   THEN t.total_fc_seats
      WHEN r.seat_class = 'ECON' THEN t.total_econ_seats
      ELSE NULL
    END
    - SUM(CASE WHEN r.seat_status = 'CONFIRMED' THEN 1 ELSE 0 END) AS seats_available,
    GREATEST(
      5 - SUM(CASE WHEN r.seat_status = 'WAITLISTED' THEN 1 ELSE 0 END),
      0
    ) AS waitlist_slots_left
FROM   CRS_TRAIN_INFO t
JOIN   CRS_RESERVATION r
       ON t.train_id = r.train_id
GROUP  BY
       r.travel_date,
       t.train_number,
       t.source_station,
       t.dest_station,
       r.seat_class,
       CASE
         WHEN r.seat_class = 'FC'   THEN t.total_fc_seats
         WHEN r.seat_class = 'ECON' THEN t.total_econ_seats
         ELSE NULL
       END;
/

------------------------------------------------------------------
-- VIEW 2: CRS_V_PASSENGER_BOOKING_SUMMARY
--   - One row per passenger with aggregated booking stats
------------------------------------------------------------------
CREATE OR REPLACE VIEW CRS_V_PASSENGER_BOOKING_SUMMARY AS
SELECT
    p.passenger_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone,
    COUNT(r.booking_id)                                                AS total_bookings,
    SUM(CASE WHEN r.seat_status = 'CONFIRMED' THEN 1 ELSE 0 END)       AS confirmed_count,
    SUM(CASE WHEN r.seat_status = 'WAITLISTED' THEN 1 ELSE 0 END)      AS waitlisted_count,
    SUM(CASE WHEN r.seat_status = 'CANCELLED'  THEN 1 ELSE 0 END)      AS cancelled_count
FROM   CRS_PASSENGER   p
LEFT JOIN CRS_RESERVATION r
       ON p.passenger_id = r.passenger_id
GROUP  BY
       p.passenger_id,
       p.first_name,
       p.last_name,
       p.email,
       p.phone;
/

------------------------------------------------------------------
-- VIEW 3: CRS_V_WAITLIST_DETAIL
--   - Current waitlist rows with joined train + passenger info
------------------------------------------------------------------
CREATE OR REPLACE VIEW CRS_V_WAITLIST_DETAIL AS
SELECT
    r.travel_date,
    t.train_number,
    r.seat_class,
    r.booking_id,
    r.waitlist_position,
    p.passenger_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone
FROM   CRS_RESERVATION r
JOIN   CRS_TRAIN_INFO  t ON r.train_id      = t.train_id
JOIN   CRS_PASSENGER   p ON r.passenger_id  = p.passenger_id
WHERE  r.seat_status = 'WAITLISTED';
/

------------------------------------------------------------------
-- PACKAGE: PKG_CRS_REPORTS (READ-ONLY REPORTS)
------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_CRS_REPORTS AS

  ----------------------------------------------------------------
  -- Report 1: Daily train load for a given date
  --   Shows each train/class and its load
  ----------------------------------------------------------------
  PROCEDURE print_daily_train_load (
    p_travel_date IN DATE
  );

  ----------------------------------------------------------------
  -- Report 2: Passenger booking history
  --   By passenger email (more user-friendly)
  ----------------------------------------------------------------
  PROCEDURE print_passenger_history (
    p_email IN CRS_PASSENGER.email%TYPE
  );

  ----------------------------------------------------------------
  -- Report 3: Waitlist details for a given train/date/class
  ----------------------------------------------------------------
  PROCEDURE print_waitlist_detail (
    p_train_number IN CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date  IN DATE,
    p_seat_class   IN CRS_RESERVATION.seat_class%TYPE
  );

END PKG_CRS_REPORTS;
/
SHOW ERRORS PACKAGE PKG_CRS_REPORTS;
 

CREATE OR REPLACE PACKAGE BODY PKG_CRS_REPORTS AS

  PROCEDURE print_daily_train_load (
    p_travel_date IN DATE
  ) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DAILY TRAIN LOAD for '
                         || TO_CHAR(TRUNC(p_travel_date),'YYYY-MM-DD')
                         || ' ===');

    FOR rec IN (
      SELECT *
      FROM   CRS_V_TRAIN_DAILY_LOAD
      WHERE  travel_date = TRUNC(p_travel_date)
      ORDER  BY train_number, seat_class
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        'Train '||rec.train_number||
        ' ('||rec.source_station||' -> '||rec.dest_station||'), '||
        'Class='||rec.seat_class||
        ' | total='||rec.total_seats||
        ' | confirmed='||rec.confirmed_seats||
        ' | waitlisted='||rec.waitlisted_seats||
        ' | cancelled='||rec.cancelled_seats||
        ' | seats_available='||rec.seats_available||
        ' | waitlist_slots_left='||rec.waitlist_slots_left
      );
    END LOOP;
  END print_daily_train_load;


  PROCEDURE print_passenger_history (
    p_email IN CRS_PASSENGER.email%TYPE
  ) IS
    v_passenger_id CRS_PASSENGER.passenger_id%TYPE;
    v_name         VARCHAR2(200);
  BEGIN
    -- Identify passenger
    SELECT passenger_id,
           first_name || ' ' || last_name
    INTO   v_passenger_id,
           v_name
    FROM   CRS_PASSENGER
    WHERE  email = p_email;

    DBMS_OUTPUT.PUT_LINE(
      '=== BOOKING HISTORY for '||v_name||
      ' ('||p_email||'), ID='||v_passenger_id||' ==='
    );

    FOR rec IN (
      SELECT
         r.booking_id,
         r.travel_date,
         r.booking_date,
         t.train_number,
         t.source_station,
         t.dest_station,
         r.seat_class,
         r.seat_status,
         r.waitlist_position
      FROM   CRS_RESERVATION r
      JOIN   CRS_TRAIN_INFO t
             ON r.train_id = t.train_id
      WHERE  r.passenger_id = v_passenger_id
      ORDER  BY r.travel_date, r.booking_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        'Booking '||rec.booking_id||
        ' | Date='||TO_CHAR(rec.travel_date,'YYYY-MM-DD')||
        ' | Train='||rec.train_number||
        ' ('||rec.source_station||'->'||rec.dest_station||')'||
        ' | Class='||rec.seat_class||
        ' | Status='||rec.seat_status||
        CASE
          WHEN rec.waitlist_position IS NOT NULL
            THEN ' | WL_POS='||rec.waitlist_position
          ELSE ''
        END
      );
    END LOOP;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE(
        'print_passenger_history: No passenger found with email '||p_email
      );
  END print_passenger_history;


  PROCEDURE print_waitlist_detail (
    p_train_number IN CRS_TRAIN_INFO.train_number%TYPE,
    p_travel_date  IN DATE,
    p_seat_class   IN CRS_RESERVATION.seat_class%TYPE
  ) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(
      '=== WAITLIST DETAIL: Train '||p_train_number||
      ', Date='||TO_CHAR(TRUNC(p_travel_date),'YYYY-MM-DD')||
      ', Class='||p_seat_class||' ==='
    );

    FOR rec IN (
      SELECT
         booking_id,
         waitlist_position,
         passenger_id,
         first_name,
         last_name,
         email,
         phone
      FROM   CRS_V_WAITLIST_DETAIL
      WHERE  train_number  = p_train_number
      AND    travel_date   = TRUNC(p_travel_date)
      AND    seat_class    = p_seat_class
      ORDER  BY waitlist_position, booking_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        'WL_POS='||rec.waitlist_position||
        ' | booking_id='||rec.booking_id||
        ' | passenger_id='||rec.passenger_id||
        ' | '||rec.first_name||' '||rec.last_name||
        ' | email='||rec.email||
        ' | phone='||rec.phone
      );
    END LOOP;
  END print_waitlist_detail;

END PKG_CRS_REPORTS;
/
SHOW ERRORS PACKAGE BODY PKG_CRS_REPORTS;
 

------------------------------------------------------------------
-- Grant report package + views to application user
------------------------------------------------------------------
GRANT SELECT ON CRS_V_TRAIN_DAILY_LOAD       TO TRAIN_APP;
GRANT SELECT ON CRS_V_PASSENGER_BOOKING_SUMMARY TO TRAIN_APP;
GRANT SELECT ON CRS_V_WAITLIST_DETAIL        TO TRAIN_APP;

GRANT EXECUTE ON PKG_CRS_REPORTS             TO TRAIN_APP;
------------------------------------------------------------------
-- END (TRAIN_DATA)
------------------------------------------------------------------
