SET SERVEROUTPUT ON;


--PASSENGER MANAGEMENT TEST CASES  (TRAIN_APP USER)
--This script validates:
---> CREATE_PASSENGER  (success + duplicate constraint)
---> UPDATE_CONTACT    (success, invalid passenger, duplicate emails)
---> GET_AGE_CATEGORY  (MINOR / ADULT / SENIOR validation)


------------------------------------------------------------
-- TEST 1: Create a valid passenger (should SUCCEED)
------------------------------------------------------------
DECLARE
  v_passenger_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Arch',
    p_middle_name  => NULL,
    p_last_name    => 'Mani',
    p_dob          => DATE '1997-06-10',
    p_addr_line1   => '124 Boston St',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '02114',
    p_email        => 'arch.test@example.com',
    p_phone        => '9998886677',
    p_passenger_id => v_passenger_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST1: PASSENGER CREATED, ID = ' || v_passenger_id);
  --COMMIT;  -- keep this passenger for later tests

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST1: UNEXPECTED ERROR -> ' || SQLERRM);
    
END;
/

ROLLBACK;


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
    p_email        => 'john.carter@example.com', -- DUPLICATE email
    p_phone        => '6175550001',              -- DUPLICATE phone
    p_passenger_id => v_passenger_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST2: ERROR, THIS SHOULD NOT BE PRINTED');
  --COMMIT;  -- would only happen if test failed (no error)

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST2: EXPECTED ERROR -> ' || SQLERRM);
    
END;
/

ROLLBACK;

------------------------------------------------------------
-- TEST 3: Update contact for existing passenger (SUCCESS)
--         Change Passenger Arch's email/phone to new unique values
------------------------------------------------------------
DECLARE
  v_passenger_id NUMBER;
BEGIN
  SELECT passenger_id
  INTO   v_passenger_id
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  email = 'john.carter@example.com';

  TRAIN_DATA.pkg_passenger_mgmt.update_contact(
    p_passenger_id => v_passenger_id,
    p_email        => 'john.carter@updated.com',
    p_phone        => '6175550001'
  );

  DBMS_OUTPUT.PUT_LINE('TEST3: Contact and Phone number updated successfully for passenger_id = '||v_passenger_id);
  --COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST3: UNEXPECTED ERROR -> ' || SQLERRM);
    
END;
/
ROLLBACK;


------------------------------------------------------------
-- TEST 4: Update non-existing passenger (should FAIL)
------------------------------------------------------------
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.update_contact(
    p_passenger_id => 999999,  -- does not exist
    p_email        => 'no.such.user@example.com',
    p_phone        => '1112223333'
  );

  DBMS_OUTPUT.PUT_LINE('TEST4: ERROR, THIS SHOULD NOT BE PRINTED');
  --COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST4: EXPECTED ERROR -> ' || SQLERRM);
    
END;
/

ROLLBACK;
------------------------------------------------------------


------------------------------------------------------------
-- TEST 5: Duplicate email/phone on update (should Fail)
-- Steps:
--   1) Create a second passenger with a distinct email/phone
--   2) Try to update Arch to use the second passenger's email/phone
------------------------------------------------------------
DECLARE
  v_john_id   NUMBER;
  v_second_id  NUMBER;
BEGIN
  -- Step 1
  SELECT passenger_id
  INTO   v_john_id
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  email = 'john.carter@example.com';

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
  --COMMIT;  -- persist second passenger

  -- Step 3: try to update Aryaa with same email/phone as second passenger
  BEGIN
    TRAIN_DATA.pkg_passenger_mgmt.update_contact(
      p_passenger_id => v_john_id,
      p_email        => 'second.user@example.com', -- DUPLICATE email
      p_phone        => '8885554444'               -- DUPLICATE phone
    );

    DBMS_OUTPUT.PUT_LINE('TEST5: ERROR, THIS SHOULD NOT BE PRINTED (duplicate).');
    --COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('TEST5: EXPECTED ERROR (duplicate contact) -> ' || SQLERRM);
      ROLLBACK;
  END;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST5: UNEXPECTED OUTER ERROR -> ' || SQLERRM);
    
END;
/
ROLLBACK;

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
--TEST 7: INVALID ZIP FORMAT (SHOULD FAIL CHECK CONSTRAINT)
------------------------------------------------------------
DECLARE
  v_id NUMBER;
BEGIN
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Priyanka',
    p_middle_name  => NULL,
    p_last_name    => 'Vadivel',
    p_dob          => DATE '1992-02-02',
    p_addr_line1   => '123 Beacon Street',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '0211',          -- invalid (4 digits only)
    p_email        => 'priyanka.invalid.zip@test.com',
    p_phone        => '7776665555',
    p_passenger_id => v_id
  );

  DBMS_OUTPUT.PUT_LINE('TEST 7: ERROR - SHOULD NOT INSERT');
  --COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'TEST 7: EXPECTED ERROR (invalid zip) -> ' || SQLERRM
    );
    
END;
/

ROLLBACK;

------------------------------------------------------------
--TEST 8: UPDATE CONTACT WITH INVALID PHONE FORMAT (SHOULD FAIL)
------------------------------------------------------------
DECLARE
  v_id NUMBER;
BEGIN
  -- Get an existing, valid passenger
  SELECT passenger_id
  INTO   v_id
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  ROWNUM = 1;  -- pick any existing passenger

  TRAIN_DATA.pkg_passenger_mgmt.update_contact(
    p_passenger_id => v_id,
    p_email        => 'invalid.phone@test.com',
    p_phone        => '98765'  -- invalid length
  );

  DBMS_OUTPUT.PUT_LINE('TEST 8: ERROR - SHOULD NOT SUCCEED');
  --COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'TEST 8: EXPECTED ERROR (invalid phone) -> ' || SQLERRM
    );
    
END;
/
ROLLBACK;

------------------------------------------------------------
--TEST 9: CREATE PASSENGER AND VALIDATE PERSISTED DETAILS
------------------------------------------------------------
DECLARE
  v_pid       NUMBER;
  v_fname     TRAIN_DATA.CRS_PASSENGER.first_name%TYPE;
  v_lname     TRAIN_DATA.CRS_PASSENGER.last_name%TYPE;
  v_email     TRAIN_DATA.CRS_PASSENGER.email%TYPE;
  v_dob       DATE;
  v_age_cat   VARCHAR2(30);
BEGIN
  ---------------------------------------------------------------------
  -- 1) Create new passenger
  ---------------------------------------------------------------------
  TRAIN_DATA.pkg_passenger_mgmt.create_passenger(
    p_first_name   => 'Arul',
    p_middle_name  => NULL,
    p_last_name    => 'Vel',
    p_dob          => DATE '1998-06-20',
    p_addr_line1   => '14 Cambridge Ave',
    p_city         => 'Boston',
    p_state        => 'MA',
    p_zip          => '02135',
    p_email        => 'arulvel.validation@test.com',
    p_phone        => '6112222371',
    p_passenger_id => v_pid
  );

  DBMS_OUTPUT.PUT_LINE('TEST 9: PASSENGER CREATED -> ID=' || v_pid);

  ---------------------------------------------------------------------
  -- 2) Fetch back core details (including DOB)
  ---------------------------------------------------------------------
  SELECT first_name, last_name, email, date_of_birth
  INTO   v_fname, v_lname, v_email, v_dob
  FROM   TRAIN_DATA.CRS_PASSENGER
  WHERE  passenger_id = v_pid;

  DBMS_OUTPUT.PUT_LINE(
    'TEST 9: DB READ BACK -> ' ||
    v_fname || ' ' || v_lname ||
    ', Email=' || v_email ||
    ', DOB=' || TO_CHAR(v_dob,'YYYY-MM-DD')
  );

  ---------------------------------------------------------------------
  -- 3) Compute age category USING DOB
  ---------------------------------------------------------------------
  v_age_cat := TRAIN_DATA.pkg_passenger_mgmt.get_age_category(
                  p_dob => v_dob
               );

  DBMS_OUTPUT.PUT_LINE(
    'TEST 9: AGE CATEGORY RESULT -> ' || v_age_cat
  );

  ---------------------------------------------------------------------
  -- 4) Final success
  ---------------------------------------------------------------------
  DBMS_OUTPUT.PUT_LINE(
    'TEST 9 SUCCESS: Passenger saved and age category validated.'
  );

  --COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'TEST 9 FAILURE -> ' || SQLERRM
    );
    
END;
/
ROLLBACK;

