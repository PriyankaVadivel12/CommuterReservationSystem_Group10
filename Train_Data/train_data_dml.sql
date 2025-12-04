------------------------------------------------------------------
-- SEED DATA FOR TRAIN MANAGEMENT SYSTEM
-- Run as TRAIN_DATA
------------------------------------------------------------------

----------------------------
-- 1. Insert 7 days
----------------------------
INSERT INTO CRS_DAY_SCHEDULE (sch_id, day_of_week, is_week_end)
VALUES (seq_crs_day_schedule.NEXTVAL, 'MON', 'N');

INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'TUE', 'N');
INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'WED', 'N');
INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'THU', 'N');
INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'FRI', 'N');
INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'SAT', 'Y');
INSERT INTO CRS_DAY_SCHEDULE VALUES (seq_crs_day_schedule.NEXTVAL, 'SUN', 'Y');

COMMIT;


----------------------------
-- 2. Insert sample trains
--    (3 realistic trains)
----------------------------
INSERT INTO CRS_TRAIN_INFO (
    train_id, train_number, source_station, dest_station,
    total_fc_seats, total_econ_seats, fc_seat_fare, econ_seat_fare
) VALUES (
    seq_crs_train_info.NEXTVAL, 'T101', 'Boston', 'New York',
    40, 40, 120.00, 70.00
);

INSERT INTO CRS_TRAIN_INFO VALUES (
    seq_crs_train_info.NEXTVAL, 'T202', 'Chicago', 'Detroit',
    40, 40, 140.00, 80.00
);

INSERT INTO CRS_TRAIN_INFO VALUES (
    seq_crs_train_info.NEXTVAL, 'T303', 'Houston', 'Dallas',
    40, 40, 110.00, 65.00
);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T304', 'San Francisco', 'Los Angeles', 50, 60, 150.00, 95.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T305', 'Seattle', 'Portland', 40, 50, 90.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T306', 'Miami', 'Orlando', 45, 55, 85.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T307', 'Atlanta', 'Charlotte', 48, 52, 100.00, 60.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T308', 'Denver', 'Salt Lake City', 42, 58, 130.00, 75.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T309', 'Phoenix', 'Las Vegas', 40, 40, 95.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T310', 'Philadelphia', 'Washington DC', 38, 62, 110.00, 65.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T311', 'New York', 'Baltimore', 45, 55, 105.00, 60.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T312', 'Dallas', 'Austin', 50, 50, 95.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T313', 'San Diego', 'Los Angeles', 40, 60, 80.00, 45.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T314', 'San Jose', 'Sacramento', 42, 48, 75.00, 40.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T315', 'Cleveland', 'Columbus', 40, 40, 85.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T316', 'Tampa', 'Jacksonville', 50, 50, 95.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T317', 'Nashville', 'Memphis', 40, 60, 100.00, 60.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T318', 'Kansas City', 'St. Louis', 45, 55, 90.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T319', 'Minneapolis', 'Milwaukee', 46, 54, 120.00, 70.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T320', 'Cincinnati', 'Louisville', 44, 56, 95.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T321', 'Indianapolis', 'Chicago', 40, 60, 110.00, 65.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T322', 'Buffalo', 'Rochester', 42, 48, 75.00, 40.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T323', 'Fresno', 'Bakersfield', 40, 60, 70.00, 35.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T324', 'Portland', 'Eugene', 38, 62, 85.00, 45.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T325', 'Omaha', 'Lincoln', 40, 40, 65.00, 30.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T326', 'Raleigh', 'Durham', 50, 50, 60.00, 25.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T327', 'Charlotte', 'Raleigh', 45, 55, 95.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T328', 'Houston', 'San Antonio', 40, 60, 85.00, 45.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T329', 'El Paso', 'Albuquerque', 48, 52, 120.00, 70.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T330', 'Salt Lake City', 'Boise', 40, 40, 140.00, 80.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T331', 'Richmond', 'Washington DC', 40, 60, 90.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T332', 'Baltimore', 'Philadelphia', 38, 62, 105.00, 60.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T333', 'Las Vegas', 'Los Angeles', 46, 54, 110.00, 65.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T334', 'Orlando', 'Tampa', 40, 40, 75.00, 40.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T335', 'Detroit', 'Cleveland', 50, 50, 100.00, 55.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T336', 'Pittsburgh', 'Philadelphia', 40, 60, 135.00, 80.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T337', 'New Orleans', 'Baton Rouge', 42, 48, 70.00, 35.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T338', 'San Antonio', 'Austin', 40, 40, 65.00, 30.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T339', 'Denver', 'Boulder', 50, 50, 55.00, 25.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T340', 'Spokane', 'Seattle', 45, 55, 100.00, 60.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T341', 'Anchorage', 'Fairbanks', 40, 60, 160.00, 95.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T342', 'Honolulu', 'Hilo', 38, 62, 180.00, 110.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T343', 'Boise', 'Twin Falls', 40, 40, 70.00, 35.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T344', 'Reno', 'Sacramento', 42, 48, 90.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T345', 'Des Moines', 'Omaha', 45, 55, 85.00, 45.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T346', 'Madison', 'Milwaukee', 40, 60, 80.00, 40.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T347', 'Columbus', 'Dayton', 40, 40, 75.00, 35.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T348', 'Rochester', 'Syracuse', 40, 60, 65.00, 30.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T349', 'Albany', 'Buffalo', 50, 50, 110.00, 65.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T350', 'Wichita', 'Kansas City', 40, 40, 90.00, 50.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T351', 'Tulsa', 'Oklahoma City', 40, 60, 80.00, 40.00);
INSERT INTO CRS_TRAIN_INFO VALUES (
seq_crs_train_info.NEXTVAL, 'T352', 'Birmingham', 'Montgomery', 40, 40, 70.00, 35.00);



COMMIT;


----------------------------
-- Helper: Get day IDs
----------------------------
-- These SELECT statements help you know sch_id for each weekday
-- (Do not comment them out; you will see results when running)
SELECT * FROM CRS_DAY_SCHEDULE ORDER BY sch_id;
SELECT * FROM CRS_TRAIN_INFO ORDER BY train_id;


----------------------------
-- 3. Insert train schedules
-- NOTE: use real sch_id values returned above
----------------------------

-- For reference:
-- sch_id = 1 → MON
-- sch_id = 2 → TUE
-- sch_id = 3 → WED
-- sch_id = 4 → THU
-- sch_id = 5 → FRI
-- sch_id = 6 → SAT
-- sch_id = 7 → SUN

-- For reference:
-- train_id = 1 → T101 (Boston → New York)
-- train_id = 2 → T202 (Chicago → Detroit)
-- train_id = 3 → T303 (Houston → Dallas)



----------------------------
-- Train T101 runs all 7 days
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 1, 'Y');
  END LOOP;
END;
/

----------------------------
-- Train T202 runs Mon–Fri only
----------------------------
BEGIN
  FOR i IN 1..5 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 2, 'Y');
  END LOOP;
END;
/

----------------------------
-- Train T303 runs weekends only (Sat, Sun)
----------------------------
BEGIN
  FOR i IN 6..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 3, 'Y');
  END LOOP;
END;
/
----------------------------
-- 4. Train T404 runs Mon, Wed, Fri
----------------------------
BEGIN
  FOR i IN 1..5 LOOP
    IF i IN (1,3,5) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 4, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 5. Train T505 runs Tue, Thu, Sat
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (2,4,6) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 5, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 6. Train T606 runs daily except Wednesday
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i != 3 THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 6, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 7. Train T707 runs weekends + Monday
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (1,6,7) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 7, 'Y');
    END IF;
  END LOOP;
END;
/
    ----------------------------
-- 8. Train T808 runs Mon–Thu
----------------------------
BEGIN
  FOR i IN 1..4 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 8, 'Y');
  END LOOP;
END;
/

----------------------------
-- 9. Train T909 runs Tue–Sat
----------------------------
BEGIN
  FOR i IN 2..6 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 9, 'Y');
  END LOOP;
END;
/

----------------------------
-- 10. Train T010 runs Mon, Wed, Fri, Sun
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (1,3,5,7) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 10, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 11. Train T111 runs Wed–Sun
----------------------------
BEGIN
  FOR i IN 3..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 11, 'Y');
  END LOOP;
END;
/

----------------------------
-- 12. Train T121 runs Mon, Thu, Sat
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (1,4,6) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 12, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 13. Train T131 runs Tue, Fri
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (2,5) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 13, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 14. Train T141 runs daily except Tuesday
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i != 2 THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 14, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 15. Train T151 runs weekends only
----------------------------
BEGIN
  FOR i IN 6..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 15, 'Y');
  END LOOP;
END;
/

----------------------------
-- 16. Train T161 runs Mon–Wed
----------------------------
BEGIN
  FOR i IN 1..3 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 16, 'Y');
  END LOOP;
END;
/

----------------------------
-- 17. Train T171 runs Thu–Sun
----------------------------
BEGIN
  FOR i IN 4..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 17, 'Y');
  END LOOP;
END;
/
 ----------------------------
-- 18. Train T181 runs Mon, Tue, Thu, Fri
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (1,2,4,5) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 18, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 19. Train T191 runs Wed, Thu, Sat
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    IF i IN (3,4,6) THEN
      INSERT INTO CRS_TRAIN_SCHEDULE
        (tsch_id, sch_id, train_id, is_in_service)
      VALUES
        (seq_crs_train_schedule.NEXTVAL, i, 19, 'Y');
    END IF;
  END LOOP;
END;
/

----------------------------
-- 20. Train T201 runs all 7 days
----------------------------
BEGIN
  FOR i IN 1..7 LOOP
    INSERT INTO CRS_TRAIN_SCHEDULE
      (tsch_id, sch_id, train_id, is_in_service)
    VALUES
      (seq_crs_train_schedule.NEXTVAL, i, 20, 'Y');
  END LOOP;
END;
/

COMMIT;



COMMIT;

----------------------------
-- Verification queries
----------------------------
SELECT * FROM CRS_DAY_SCHEDULE ORDER BY sch_id;
SELECT * FROM CRS_TRAIN_INFO ORDER BY train_id;
SELECT * FROM CRS_TRAIN_SCHEDULE ORDER BY train_id, sch_id;
