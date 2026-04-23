-- EXERCISE 1
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

BEGIN
    UPDATE accounts
    SET balance = balance - 50
    WHERE account_id = 3;

    UPDATE accounts
    SET balance = balance + 50
    WHERE account_id = 1;

    COMMIT;
END;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- EXERCISE 2
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

CREATE OR REPLACE PROCEDURE transfer_funds(
    p_from_account  IN  NUMBER,
    p_to_account    IN  NUMBER,
    p_amount        IN  NUMBER
) AS
    v_from_balance  NUMBER;
BEGIN
    SELECT balance INTO v_from_balance
    FROM accounts
    WHERE account_id = p_from_account;

    IF v_from_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient funds in account ' || p_from_account);
    END IF;

    -- Perform the transfer
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

    -- Commit only if both succeed
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Transfer complete: $' || p_amount ||
                         ' from account ' || p_from_account ||
                         ' to account ' || p_to_account);
EXCEPTION
    WHEN OTHERS THEN
        -- Something went wrong — undo everything
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transfer failed. All changes rolled back.');
        RAISE;  -- re-raise the error so the caller knows it failed
END;

SET SERVEROUTPUT ON;
EXEC transfer_funds(2, 3, 10000);

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- EXERCISE 3
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

BEGIN
    UPDATE accounts
    SET balance = balance + 25
    WHERE account_id = 1;

    SAVEPOINT before_wrongfull;

    UPDATE accounts
    SET balance = balance - 25
    WHERE account_id = 3;

    ROLLBACK TO before_wrongfull;

    UPDATE accounts
    SET balance = balance - 25
    WHERE account_id = 2;

    COMMIT;
END;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- EXERCISE 4
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id  IN  NUMBER,
    p_amount    IN  NUMBER
) AS
BEGIN
    IF p_amount < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Not a valid amount of funds' || p_amount);
    END IF;

    -- Perform the deposit
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_account_id;

    -- Commit only if both succeed
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Deposit complete: $' || p_amount ||
                         ' to account ' || p_account_id);
EXCEPTION
    WHEN OTHERS THEN
        -- Something went wrong — undo everything
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Deposit Failed. All changes rolled back.');
        RAISE;  -- re-raise the error so the caller knows it failed
END;

SET SERVEROUTPUT ON;
EXEC deposit_funds(3, 75);

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- EXERCISE 5
-- Q1:
--The reservation of the time slot and the creation of the appointment record should be inside the transaction,
--given that both operations are directly related due that the creation of an appointment needs a date and the resrvation 
--of time needs to have an appointmet to connect to, this transaction makes the database consistent. The confirmation notification 
--should be outside the transaction, since sending a message is something that can happen independently from the other
--both actions, the other actions should not block the start or commit of this one.

-- Q2:
--As there is a commit in my process, if an outsider developer decide to use the process, it can cause all
--changes to be saved, even those that were not done by the process. This affects the transactions of the develope
--given that he can no longer rollback to his previous commit.

-- Q3:
--Yes, the function calculate_copay() can be used inside a SELECT statement because functions are designed to be in a SELECT.
--By the other hand post_payment() cannot be used inside a SELECT because procedures do not return values 
--given that they are intended to perform actions or modify data instead of being part of a SELECT.