SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  PASSENGER MANAGEMENT TEST CASES  (TRAIN_APP USER)
PROMPT  This script validates:
PROMPT   -> CREATE_PASSENGER  (success + duplicate constraint)
PROMPT   -> UPDATE_CONTACT    (success, invalid passenger, duplicate emails)
PROMPT   -> GET_AGE_CATEGORY  (MINOR / ADULT / SENIOR validation)
PROMPT ============================================================


------------------------------------------------------------
-- TEST 1: Create a valid passenger (should SUCCEED)
------------------------------------------------------------
DECLARE
  v_passenger_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Aryaa',
    p_middle_name  => NULL,
    p_last_name    => 'Hanamar',
    p_dob          => DATE '1997-05-10',
    p_addr_line1   => '123 Boston St',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '02115',
    p_email        => 'aryaa.test@example.com',
    p_phone        => '9998887777',
    p_passenger_id => v_passenger_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST1: PASSENGER CREATED, ID = ' || v_passenger_id);
  COMMIT;  -- keep this passenger for later tests

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST1: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------
-- Verify TEST 1 result (optional)
------------------------------------------------------------
SELECT passenger_id, first_name, last_name, email, phone
FROM   TRAIN_DATA.CRS_PASSENGER
WHERE  email = 'aryaa.test@example.com';
/


------------------------------------------------------------
-- TEST 2: Create passenger with same email/phone (should FAIL)
-- EXPECTED: ORA-20010 (duplicate email/phone)
------------------------------------------------------------
DECLARE
  v_passenger_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Duplicate',
    p_middle_name  => NULL,
    p_last_name    => 'User',
    p_dob          => DATE '1995-01-01',
    p_addr_line1   => '456 Another St',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '02115',
    p_email        => 'aryaa.test@example.com', -- DUPLICATE email
    p_phone        => '9998887777',              -- DUPLICATE phone
    p_passenger_id => v_passenger_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST2: ERROR, THIS SHOULD NOT BE PRINTED');
  COMMIT;  -- would only happen if test failed (no error)

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST2: EXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------
-- EXTRA TESTS FOR PASSENGER MANAGEMENT
------------------------------------------------------------


------------------------------------------------------------
-- TEST 3: Update contact for existing passenger (SUCCESS)
--         Change Aryaa's email/phone to new unique values
------------------------------------------------------------
DECLARE
  v_passenger_id NUMBER;
BEGIN
  SELECT passenger_id
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  email = 'aryaa.test@example.com';

  TRAIN_DATA.pkg_passenger_mgmt.update_contact(
    p_passenger_id => v_passenger_id,
    p_email        => 'aryaa.updated@example.com',
    p_phone        => '9997776666'
  );

  DBMS_OUTPUT.PUT_LINE('TEST3: Contact updated successfully for passenger_id = '||v_passenger_id);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST3: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
-- Verify TEST 3
SELECT passenger_id, first_name, last_name, email, phone
FROM   TRAIN_DATA.CRS_PASSENGER
WHERE  email = 'aryaa.updated@example.com';
/


------------------------------------------------------------
-- TEST 4: Update non-existing passenger (should FAIL: ORA-20011)
------------------------------------------------------------
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.update_contact(
    p_passenger_id => 999999,  -- does not exist
    p_email        => 'no.such.user@example.com',
    p_phone        => '1112223333'
  );

  DBMS_OUTPUT.PUT_LINE('TEST4: ERROR, THIS SHOULD NOT BE PRINTED');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST4: EXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------


------------------------------------------------------------
-- TEST 5: Duplicate email/phone on update (should FAIL: ORA-20012)
-- Steps:
--   1) Create a second passenger with a distinct email/phone
--   2) Try to update Aryaa to use the second passenger's email/phone
------------------------------------------------------------
DECLARE
  v_aryaa_id   NUMBER;
  v_second_id  NUMBER;
BEGIN
  -- Step 1: ensure Aryaa's id (after update)
  SELECT passenger_id
  INTO   v_aryaa_id
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  email = 'aryaa.updated@example.com';

  -- Step 2: create second passenger
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Second',
    p_middle_name  => NULL,
    p_last_name    => 'User',
    p_dob          => DATE '1980-01-01',
    p_addr_line1   => '789 Some St',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '02115',
    p_email        => 'second.user@example.com',
    p_phone        => '8885554444',
    p_passenger_id => v_second_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST5: Created second passenger, ID = '||v_second_id);
  COMMIT;  -- persist second passenger

  -- Step 3: try to update Aryaa with same email/phone as second passenger
  BEGIN
    TRAIN_DATA.pkg_passenger_mgmt.update_contact(
      p_passenger_id => v_aryaa_id,
      p_email        => 'second.user@example.com', -- DUPLICATE email
      p_phone        => '8885554444'               -- DUPLICATE phone
    );

    DBMS_OUTPUT.PUT_LINE('TEST5: ERROR, THIS SHOULD NOT BE PRINTED (duplicate).');
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('TEST5: EXPECTED ERROR (duplicate contact) -> ' || SQLERRM);
      ROLLBACK;
  END;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST5: UNEXPECTED OUTER ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
-- Optional: check both passengers
SELECT passenger_id, first_name, last_name, email, phone
FROM   TRAIN_DATA.CRS_PASSENGER
WHERE  email IN ('aryaa.updated@example.com','second.user@example.com')
ORDER  BY passenger_id;
/


------------------------------------------------------------
-- TEST 6: Age / category function (MINOR / ADULT / SENIOR)
------------------------------------------------------------
DECLARE
  v_minor    VARCHAR2(20);
  v_adult    VARCHAR2(20);
  v_senior   VARCHAR2(20);
BEGIN
  v_minor  := TRAIN_DATA.pkg_passenger_mgmt.get_age_category(DATE '2015-01-01'); -- ~10 yrs
  v_adult  := TRAIN_DATA.pkg_passenger_mgmt.get_age_category(DATE '1995-01-01'); -- ~30 yrs
  v_senior := TRAIN_DATA.pkg_passenger_mgmt.get_age_category(DATE '1950-01-01'); -- ~75 yrs

  DBMS_OUTPUT.PUT_LINE('TEST6: 2015-01-01 -> '||v_minor);
  DBMS_OUTPUT.PUT_LINE('TEST6: 1995-01-01 -> '||v_adult);
  DBMS_OUTPUT.PUT_LINE('TEST6: 1950-01-01 -> '||v_senior);

  COMMIT;  -- no DML here, but keeps transaction clean

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST6: UNEXPECTED ERROR -> ' || SQLERRM);
    ROLLBACK;
END;
/
------------------------------------------------------------
-- END OF PASSENGER MANAGEMENT TESTS
------------------------------------------------------------
