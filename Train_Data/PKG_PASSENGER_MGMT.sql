------------------------------------------------------------
-- PACKAGE SPECIFICATION
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_passenger_mgmt AS

  ----------------------------------------------------------------
  -- PROCEDURE: create_passenger
  -- Inserts a new passenger. Email and phone must be unique.
  ----------------------------------------------------------------
  PROCEDURE create_passenger (
    p_first_name    IN  CRS_PASSENGER.first_name%TYPE,
    p_middle_name   IN  CRS_PASSENGER.middle_name%TYPE,
    p_last_name     IN  CRS_PASSENGER.last_name%TYPE,
    p_dob           IN  CRS_PASSENGER.date_of_birth%TYPE,
    p_addr_line1    IN  CRS_PASSENGER.address_line1%TYPE,
    p_city          IN  CRS_PASSENGER.address_city%TYPE,
    p_state         IN  CRS_PASSENGER.address_state%TYPE,
    p_zip           IN  CRS_PASSENGER.address_zip%TYPE,
    p_email         IN  CRS_PASSENGER.email%TYPE,
    p_phone         IN  CRS_PASSENGER.phone%TYPE,
    p_passenger_id  OUT CRS_PASSENGER.passenger_id%TYPE
  );

  ----------------------------------------------------------------
  -- PROCEDURE: update_contact
  -- Updates passenger email/phone with uniqueness validation.
  ----------------------------------------------------------------
  PROCEDURE update_contact (
    p_passenger_id  IN  CRS_PASSENGER.passenger_id%TYPE,
    p_email         IN  CRS_PASSENGER.email%TYPE,
    p_phone         IN  CRS_PASSENGER.phone%TYPE
  );

  ----------------------------------------------------------------
  -- FUNCTION: get_age_years
  -- Returns age in years at reference date (default = today)
  ----------------------------------------------------------------
  FUNCTION get_age_years (
    p_dob       IN DATE,
    p_ref_date  IN DATE DEFAULT TRUNC(SYSDATE)
  ) RETURN NUMBER;

  ----------------------------------------------------------------
  -- FUNCTION: get_age_category
  -- Returns MINOR (<18), ADULT (18–59), SENIOR (>=60)
  ----------------------------------------------------------------
  FUNCTION get_age_category (
    p_dob       IN DATE,
    p_ref_date  IN DATE DEFAULT TRUNC(SYSDATE)
  ) RETURN VARCHAR2;

END pkg_passenger_mgmt;
/
SHOW ERRORS PACKAGE pkg_passenger_mgmt;



------------------------------------------------------------
-- PACKAGE BODY
------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_passenger_mgmt AS

  ----------------------------------------------------------------
  -- create_passenger
  ----------------------------------------------------------------
  PROCEDURE create_passenger (
    p_first_name    IN  CRS_PASSENGER.first_name%TYPE,
    p_middle_name   IN  CRS_PASSENGER.middle_name%TYPE,
    p_last_name     IN  CRS_PASSENGER.last_name%TYPE,
    p_dob           IN  CRS_PASSENGER.date_of_birth%TYPE,
    p_addr_line1    IN  CRS_PASSENGER.address_line1%TYPE,
    p_city          IN  CRS_PASSENGER.address_city%TYPE,
    p_state         IN  CRS_PASSENGER.address_state%TYPE,
    p_zip           IN  CRS_PASSENGER.address_zip%TYPE,
    p_email         IN  CRS_PASSENGER.email%TYPE,
    p_phone         IN  CRS_PASSENGER.phone%TYPE,
    p_passenger_id  OUT CRS_PASSENGER.passenger_id%TYPE
  ) IS
  BEGIN
    p_passenger_id := seq_crs_passenger.NEXTVAL;

    INSERT INTO CRS_PASSENGER (
      passenger_id, first_name, middle_name, last_name,
      date_of_birth, address_line1, address_city,
      address_state, address_zip, email, phone
    )
    VALUES (
      p_passenger_id, p_first_name, p_middle_name, p_last_name,
      p_dob, p_addr_line1, p_city,
      p_state, p_zip, p_email, p_phone
    );

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(
        -20010,
        'Passenger with same email or phone already exists.'
      );
  END create_passenger;



  ----------------------------------------------------------------
  -- update_contact
  ----------------------------------------------------------------
  PROCEDURE update_contact (
    p_passenger_id  IN  CRS_PASSENGER.passenger_id%TYPE,
    p_email         IN  CRS_PASSENGER.email%TYPE,
    p_phone         IN  CRS_PASSENGER.phone%TYPE
  ) IS
    v_dummy NUMBER;
  BEGIN
    -- ensure passenger exists
    SELECT 1 INTO v_dummy
    FROM CRS_PASSENGER
    WHERE passenger_id = p_passenger_id;

    UPDATE CRS_PASSENGER
    SET email = p_email,
        phone = p_phone
    WHERE passenger_id = p_passenger_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20011, 'Passenger does not exist.');
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(
        -20012,
        'Another passenger already uses this email or phone.'
      );
  END update_contact;



  ----------------------------------------------------------------
  -- get_age_years
  ----------------------------------------------------------------
  FUNCTION get_age_years (
    p_dob       IN DATE,
    p_ref_date  IN DATE DEFAULT TRUNC(SYSDATE)
  ) RETURN NUMBER IS
    v_years NUMBER;
  BEGIN
    IF p_dob IS NULL THEN
      RETURN NULL;
    END IF;

    v_years := TRUNC(
                 MONTHS_BETWEEN(
                   TRUNC(p_ref_date),
                   TRUNC(p_dob)
                 ) / 12
               );
    RETURN v_years;
  END get_age_years;



  ----------------------------------------------------------------
  -- get_age_category
  ----------------------------------------------------------------
  FUNCTION get_age_category (
    p_dob       IN DATE,
    p_ref_date  IN DATE DEFAULT TRUNC(SYSDATE)
  ) RETURN VARCHAR2 IS
    v_age NUMBER;
  BEGIN
    v_age := get_age_years(p_dob, p_ref_date);

    IF v_age IS NULL THEN
      RETURN NULL;
    ELSIF v_age < 18 THEN
      RETURN 'MINOR';
    ELSIF v_age < 60 THEN
      RETURN 'ADULT';
    ELSE
      RETURN 'SENIOR';
    END IF;
  END get_age_category;

END pkg_passenger_mgmt;
/

SHOW ERRORS PACKAGE BODY pkg_passenger_mgmt;
