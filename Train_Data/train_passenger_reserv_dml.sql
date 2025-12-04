------------------------------------------------------------
-- SAMPLE DATA FOR REPORTS (TRAIN_DATA)
-- Safe to re-run
------------------------------------------------------------

-----------------------------
-- 1) CLEAN SAMPLE RANGE
-----------------------------
DELETE FROM CRS_RESERVATION
 WHERE booking_id BETWEEN 10001 AND 10020;

DELETE FROM CRS_PASSENGER
 WHERE passenger_id BETWEEN 2001 AND 2010;

COMMIT;


-----------------------------
-- 2) SAMPLE PASSENGERS
--   (structure from your DDL)
--   CRS_PASSENGER(
--     passenger_id, first_name, middle_name, last_name,
--     date_of_birth, address_line1, address_city,
--     address_state, address_zip, email, phone
--   )
-----------------------------
INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2001, 'John',   NULL,  'Carter',
   DATE '1988-05-10',
   '12 Boylston St', 'Boston', 'MA', '02115',
   'john.carter@example.com', '6175550001');

INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2002, 'Emily',  NULL,  'Watson',
   DATE '1994-03-21',
   '45 Huntington Ave', 'Boston', 'MA', '02116',
   'emily.watson@example.com', '6175550002');

INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2003, 'Rahul',  NULL,  'Mehta',
   DATE '1982-11-02',
   '90 Tremont St', 'Boston', 'MA', '02118',
   'rahul.mehta@example.com', '6175550003');

INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2004, 'Sophia', NULL,  'Turner',
   DATE '1990-07-15',
   '150 Beacon St', 'Boston', 'MA', '02120',
   'sophia.t@example.com', '6175550004');

INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2005, 'Michael', NULL, 'Brown',
   DATE '1970-01-09',
   '210 Commonwealth Ave', 'Boston', 'MA', '02125',
   'michael.b@example.com', '6175550005');

INSERT INTO CRS_PASSENGER
  (passenger_id, first_name, middle_name, last_name,
   date_of_birth, address_line1, address_city,
   address_state, address_zip, email, phone)
VALUES
  (2006, 'Ariana', NULL, 'Lopez',
   DATE '2002-09-30',
   '33 Mass Ave', 'Boston', 'MA', '02130',
   'ariana.lopez@example.com', '6175550006');

COMMIT;


-----------------------------
-- 3) SAMPLE RESERVATIONS
--   CRS_RESERVATION(
--     booking_id, passenger_id, train_id,
--     travel_date, booking_date,
--     seat_class, seat_status, waitlist_position
--   )
--
-- Assumes trains T101, T202, T303 exist in CRS_TRAIN_INFO.
-- If some train_number doesn’t exist, that INSERT just does 0 rows.
-----------------------------

-- T101 / ECON – mix of CONFIRMED, CANCELLED, WAITLISTED
INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10001, 2001, train_id,
  TRUNC(SYSDATE) + 1, TRUNC(SYSDATE),
  'ECON', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T101';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10002, 2002, train_id,
  TRUNC(SYSDATE) + 1, TRUNC(SYSDATE),
  'ECON', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T101';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10003, 2003, train_id,
  TRUNC(SYSDATE) + 1, TRUNC(SYSDATE),
  'ECON', 'CANCELLED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T101';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10004, 2004, train_id,
  TRUNC(SYSDATE) + 1, TRUNC(SYSDATE),
  'ECON', 'WAITLISTED', 1
FROM CRS_TRAIN_INFO
WHERE train_number = 'T101';


-- T202 / FC – couple of confirmed + one waitlist
INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10005, 2001, train_id,
  TRUNC(SYSDATE) + 2, TRUNC(SYSDATE),
  'FC', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T202';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10006, 2005, train_id,
  TRUNC(SYSDATE) + 2, TRUNC(SYSDATE),
  'FC', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T202';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10007, 2006, train_id,
  TRUNC(SYSDATE) + 2, TRUNC(SYSDATE),
  'FC', 'WAITLISTED', 1
FROM CRS_TRAIN_INFO
WHERE train_number = 'T202';


-- T303 / ECON – more waitlist and cancellations
INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10008, 2002, train_id,
  TRUNC(SYSDATE) + 3, TRUNC(SYSDATE),
  'ECON', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T303';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10009, 2003, train_id,
  TRUNC(SYSDATE) + 3, TRUNC(SYSDATE),
  'ECON', 'CONFIRMED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T303';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10010, 2004, train_id,
  TRUNC(SYSDATE) + 3, TRUNC(SYSDATE),
  'ECON', 'WAITLISTED', 1
FROM CRS_TRAIN_INFO
WHERE train_number = 'T303';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10011, 2005, train_id,
  TRUNC(SYSDATE) + 3, TRUNC(SYSDATE),
  'ECON', 'WAITLISTED', 2
FROM CRS_TRAIN_INFO
WHERE train_number = 'T303';

INSERT INTO CRS_RESERVATION
  (booking_id, passenger_id, train_id,
   travel_date, booking_date,
   seat_class, seat_status, waitlist_position)
SELECT
  10012, 2006, train_id,
  TRUNC(SYSDATE) + 3, TRUNC(SYSDATE),
  'ECON', 'CANCELLED', NULL
FROM CRS_TRAIN_INFO
WHERE train_number = 'T303';

COMMIT;


-----------------------------
-- 4) QUICK CHECKS FOR DEMO
-----------------------------
-- Passengers
SELECT passenger_id,
       first_name || ' ' || last_name AS full_name,
       email,
       phone
FROM   CRS_PASSENGER
WHERE  passenger_id BETWEEN 2001 AND 2006
ORDER  BY passenger_id;

-- Reservations joined with train + passenger
SELECT r.booking_id,
       p.first_name || ' ' || p.last_name AS passenger_name,
       t.train_number,
       r.travel_date,
       r.booking_date,
       r.seat_class,
       r.seat_status,
       r.waitlist_position
FROM   CRS_RESERVATION r
JOIN   CRS_PASSENGER   p ON p.passenger_id = r.passenger_id
JOIN   CRS_TRAIN_INFO  t ON t.train_id     = r.train_id
WHERE  r.booking_id BETWEEN 10001 AND 10012
ORDER  BY r.booking_id;

select * from CRS_PASSENGER;
select * from CRS_DAY_SCHEDULE;
select * from CRS_RESERVATION;
select * from CRS_TRAIN_INFO;
select * from CRS_TRAIN_SCHEDULE;
