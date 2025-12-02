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

COMMIT;


----------------------------
-- Verification queries
----------------------------
SELECT * FROM CRS_DAY_SCHEDULE ORDER BY sch_id;
SELECT * FROM CRS_TRAIN_INFO ORDER BY train_id;
SELECT * FROM CRS_TRAIN_SCHEDULE ORDER BY train_id, sch_id;
