------------------------------------------------------------------
-- TRAIN MANAGEMENT SYSTEM - CORE OBJECTS
-- Run this entire script as user: TRAIN_DATA
------------------------------------------------------------------

-----------------------------
-- (OPTIONAL) CLEANUP
-----------------------------
-- Uncomment if you need to rerun from scratch.
 DROP TABLE CRS_RESERVATION   CASCADE CONSTRAINTS;
 DROP TABLE CRS_TRAIN_SCHEDULE CASCADE CONSTRAINTS;
 DROP TABLE CRS_DAY_SCHEDULE  CASCADE CONSTRAINTS;
DROP TABLE CRS_PASSENGER     CASCADE CONSTRAINTS;
DROP TABLE CRS_TRAIN_INFO    CASCADE CONSTRAINTS;
DROP SEQUENCE SEQ_CRS_TRAIN_INFO;
DROP SEQUENCE SEQ_CRS_DAY_SCHEDULE;
DROP SEQUENCE SEQ_CRS_TRAIN_SCHEDULE;
DROP SEQUENCE SEQ_CRS_PASSENGER;
DROP SEQUENCE SEQ_CRS_RESERVATION;


------------------------------------------------------------------
-- 1. CRS_TRAIN_INFO
------------------------------------------------------------------
CREATE TABLE CRS_TRAIN_INFO (
    train_id         NUMBER(10)
        CONSTRAINT pk_crs_train_info PRIMARY KEY,
    train_number     VARCHAR2(20)
        CONSTRAINT uq_crs_train_number UNIQUE
        NOT NULL,
    source_station   VARCHAR2(50)  NOT NULL,
    dest_station     VARCHAR2(50)  NOT NULL,
    total_fc_seats   NUMBER(4)     DEFAULT 40 NOT NULL,
    total_econ_seats NUMBER(4)     DEFAULT 40 NOT NULL,
    fc_seat_fare     NUMBER(10,2)  NOT NULL,
    econ_seat_fare   NUMBER(10,2)  NOT NULL,
    CONSTRAINT chk_crs_train_seats
        CHECK ( total_fc_seats  > 0
            AND total_econ_seats > 0 ),
    CONSTRAINT chk_crs_train_fares
        CHECK ( fc_seat_fare    > 0
            AND econ_seat_fare  > 0 )
);

CREATE SEQUENCE seq_crs_train_info
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


------------------------------------------------------------------
-- 2. CRS_DAY_SCHEDULE
------------------------------------------------------------------
CREATE TABLE CRS_DAY_SCHEDULE (
    sch_id       NUMBER(10)
        CONSTRAINT pk_crs_day_schedule PRIMARY KEY,
    day_of_week  VARCHAR2(10)
        CONSTRAINT uq_crs_day_of_week UNIQUE
        NOT NULL,
    is_week_end  CHAR(1) NOT NULL,
    CONSTRAINT chk_crs_is_week_end
        CHECK (is_week_end IN ('Y','N'))
);

CREATE SEQUENCE seq_crs_day_schedule
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


------------------------------------------------------------------
-- 3. CRS_TRAIN_SCHEDULE
------------------------------------------------------------------
CREATE TABLE CRS_TRAIN_SCHEDULE (
    tsch_id       NUMBER(10)
        CONSTRAINT pk_crs_train_schedule PRIMARY KEY,
    sch_id        NUMBER(10)  NOT NULL,
    train_id      NUMBER(10)  NOT NULL,
    is_in_service CHAR(1)     NOT NULL,
    CONSTRAINT fk_crs_ts_schedule
        FOREIGN KEY (sch_id)
        REFERENCES CRS_DAY_SCHEDULE (sch_id),
    CONSTRAINT fk_crs_ts_train
        FOREIGN KEY (train_id)
        REFERENCES CRS_TRAIN_INFO (train_id),
    CONSTRAINT uq_crs_ts_train_day
        UNIQUE (train_id, sch_id),
    CONSTRAINT chk_crs_ts_in_service
        CHECK (is_in_service IN ('Y','N'))
);

CREATE SEQUENCE seq_crs_train_schedule
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


------------------------------------------------------------------
-- 4. CRS_PASSENGER
------------------------------------------------------------------
CREATE TABLE CRS_PASSENGER (
    passenger_id   NUMBER(10)
        CONSTRAINT pk_crs_passenger PRIMARY KEY,
    first_name     VARCHAR2(50)   NOT NULL,
    middle_name    VARCHAR2(50),
    last_name      VARCHAR2(50)   NOT NULL,
    date_of_birth  DATE           NOT NULL,
    address_line1  VARCHAR2(100)  NOT NULL,
    address_city   VARCHAR2(50)   NOT NULL,
    address_state  VARCHAR2(50)   NOT NULL,
    address_zip    VARCHAR2(15)   NOT NULL,
    email          VARCHAR2(100)  NOT NULL
        CONSTRAINT uq_crs_passenger_email UNIQUE,
    phone          VARCHAR2(20)   NOT NULL
        CONSTRAINT uq_crs_passenger_phone UNIQUE
);

CREATE SEQUENCE seq_crs_passenger
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


------------------------------------------------------------------
-- 5. CRS_RESERVATION
------------------------------------------------------------------
CREATE TABLE CRS_RESERVATION (
    booking_id        NUMBER(10)
        CONSTRAINT pk_crs_reservation PRIMARY KEY,
    passenger_id      NUMBER(10)    NOT NULL,
    train_id          NUMBER(10)    NOT NULL,
    travel_date       DATE          NOT NULL,
    booking_date      DATE          NOT NULL,
    seat_class        CHAR(4)       NOT NULL,
    seat_status       VARCHAR2(20)  NOT NULL,
    waitlist_position NUMBER(4),
    CONSTRAINT fk_crs_res_passenger
        FOREIGN KEY (passenger_id)
        REFERENCES CRS_PASSENGER (passenger_id),
    CONSTRAINT fk_crs_res_train
        FOREIGN KEY (train_id)
        REFERENCES CRS_TRAIN_INFO (train_id),
    CONSTRAINT chk_crs_res_seat_class
        CHECK (seat_class IN ('FC','ECON')),
    CONSTRAINT chk_crs_res_seat_status
        CHECK (seat_status IN ('CONFIRMED','WAITLISTED','CANCELLED')),
    -- Waitlist rule: waitlist_position only when WAITLISTED
    CONSTRAINT chk_crs_res_waitlist
        CHECK (
              (seat_status = 'WAITLISTED'
               AND waitlist_position IS NOT NULL
               AND waitlist_position > 0)
          OR  (seat_status IN ('CONFIRMED','CANCELLED')
               AND waitlist_position IS NULL)
        )
);

CREATE SEQUENCE seq_crs_reservation
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


------------------------------------------------------------------
-- 6. Helpful Indexes
------------------------------------------------------------------
CREATE INDEX idx_crs_res_train_date_class
    ON CRS_RESERVATION (train_id, travel_date, seat_class, seat_status);

CREATE INDEX idx_crs_res_passenger
    ON CRS_RESERVATION (passenger_id);
