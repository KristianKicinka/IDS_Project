-----------------------
--- CREATE TRIGGERS ---
-----------------------
-- Card activity trigger
-- When changing or inserting new payment card - expiration date is checked
-- If it's overdue -> card_activity is set to 0, otherwise 1
CREATE OR REPLACE TRIGGER CARD_ACTIVITY
    BEFORE UPDATE OR INSERT
    ON PAYMENT_CARD
    FOR EACH ROW
BEGIN
    IF (((SUBSTR(:new.EXPIRATION_DATE, 4, 2) = SUBSTR(TO_CHAR(sysdate), 7, 2))
        AND (SUBSTR(:new.EXPIRATION_DATE, 1, 2) < SUBSTR(TO_CHAR(sysdate), 4, 2)))
        OR (SUBSTR(:new.EXPIRATION_DATE, 4, 2) < SUBSTR(TO_CHAR(sysdate), 7, 2)))
    THEN
        :new.IS_ACTIVE := 0;
    ELSE
        :new.IS_ACTIVE := 1;
    END IF;
end;
/

-- Activity card
UPDATE PAYMENT_CARD
SET EXPIRATION_DATE = '03/22'
WHERE PAYMENT_CARD_ID = 3;

SELECT *
FROM PAYMENT_CARD;


-- Transaction conversion trigger
-- When inserting new operation, if the currency is any other the EUR,
-- the amount of money is automatically converted to default currency using conversion rates in currency table
-- and currency is set to 1 (EUR)
CREATE OR REPLACE TRIGGER TRANSACTION_CONVERSION
    BEFORE INSERT
    ON OPERATION
    FOR EACH ROW
DECLARE
    ex_rate number;
BEGIN
    SELECT EXCHANGE_RATE INTO ex_rate FROM CURRENCY WHERE CURRENCY.CURRENCY_ID = :new.CURRENCY_ID;
    IF (:new.CURRENCY_ID <> 1) THEN
        :new.AMOUNT := :new.AMOUNT * ex_rate;
        :new.CURRENCY_ID := 1;
    END IF;
END;
/

INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'payment', 59.99, '12.1.2022', '13.1.2022', '14.1.2022', 0,
        'CZ5262106701002216739313', 2, 2);

SELECT *
FROM OPERATION;

-- vytvoření alespoň dvou netriviálních uložených procedur vč. jejich předvedení,
-- ve kterých se musí (dohromady) vyskytovat alespoň jednou kurzor,
-- ošetření výjimek a použití proměnné s datovým typem odkazujícím se na řádek či
-- typ sloupce tabulky (table_name.column_name%TYPE nebo table_name%ROWTYPE),

CREATE OR REPLACE PROCEDURE CHANGE_DEBITS_LIMITS_BY_COMPANY(cardCompany varchar, debitLimit number)
    IS
    card_id CARD_TYPE.CARD_TYPE_ID%type;
    CURSOR
        select_cards IS
        SELECT CARD_TYPE_ID
        FROM CARD_TYPE
        WHERE CARD_TYPE.COMPANY = cardCompany;
    limit   number;
BEGIN
    limit := debitLimit;
    IF (limit IS NULL) THEN
        limit := 0;
    ELSE
        limit := debitLimit;
    END IF;
    OPEN select_cards;
    LOOP
        FETCH select_cards INTO card_id;
        EXIT WHEN select_cards%NOTFOUND;
        UPDATE CARD_TYPE SET DEBIT_LIMIT = limit WHERE CARD_TYPE_ID = card_id;
        COMMIT;
    end loop;
    CLOSE select_cards;

EXCEPTION
    WHEN OTHERS THEN
        raise_application_error(-20001, 'An error was encountered - ' || SQLCODE || ' -ERROR- ' || SQLERRM);
END;
/
BEGIN
    CHANGE_DEBITS_LIMITS_BY_COMPANY('VISA', NULL);
END;
/

SELECT *
FROM CARD_TYPE;


CREATE OR REPLACE PROCEDURE INCREASE_SALARY(position VARCHAR, percentage NUMBER)
    IS
    old_salary EMPLOYEE.SALARY%type;
    employeeID EMPLOYEE.EMPLOYEE_ID%type;
    new_salary NUMBER;
    CURSOR select_salary IS
        SELECT SALARY, EMPLOYEE_ID
        FROM EMPLOYEE
        WHERE EMPLOYEE.WORK_POSITION = position;
BEGIN
    OPEN select_salary;
    LOOP
        FETCH select_salary INTO old_salary,employeeID;
        EXIT WHEN select_salary%NOTFOUND;
        new_salary := old_salary + (old_salary * (percentage / 100));
        UPDATE EMPLOYEE SET SALARY = new_salary WHERE EMPLOYEE.EMPLOYEE_ID = employeeID;
    end loop;
    CLOSE select_salary;
end;
/
BEGIN
    INCREASE_SALARY('Director', -50);
end;
/

SELECT WORK_POSITION, SALARY
FROM EMPLOYEE;

-- explicitní vytvoření alespoň jednoho indexu tak, aby pomohl optimalizovat zpracování dotazů,
-- přičemž musí být uveden také příslušný dotaz, na který má index vliv,
-- a v dokumentaci popsán způsob využití indexu v tomto dotazy (toto lze zkombinovat s EXPLAIN PLAN, vizte dále),


-- alespoň jedno použití EXPLAIN PLAN pro výpis plánu provedení databazového dotazu se spojením alespoň dvou tabulek,
-- agregační funkcí a klauzulí GROUP BY, přičemž v dokumentaci musí být srozumitelně popsáno,
-- jak proběhne dle toho výpisu plánu provedení dotazu, vč. objasnění použitých prostředků pro
-- jeho urychlení (např. použití indexu, druhu spojení, atp.), a dále musí být navrnut způsob,
-- jak konkrétně by bylo možné dotaz dále urychlit (např. zavedením nového indexu), navržený způsob
-- proveden (např. vytvořen index), zopakován EXPLAIN PLAN a jeho výsledek porovnán s výsledkem před provedením
-- navrženého způsobu urychlení,


-- definici přístupových práv k databázovým objektům pro druhého člena týmu,

CREATE OR REPLACE PROCEDURE ADD_PRIVILEGES(user VARCHAR)
    IS
    tableName USER_TABLES.table_name%type;
    CURSOR select_all_tables IS SELECT table_name
                                FROM USER_TABLES;
BEGIN
    OPEN select_all_tables;
    LOOP
        FETCH select_all_tables INTO tableName;
        EXIT WHEN select_all_tables%NOTFOUND;
        EXECUTE IMMEDIATE 'GRANT ALL ON ' || tableName || ' TO ' || user;
    end loop;
    CLOSE select_all_tables;
end;
/

BEGIN
    ADD_PRIVILEGES('XVALEN29');
end;
/

SELECT *
FROM table_privileges
WHERE grantee = 'XVALEN29'
ORDER BY owner, table_name;

-- vytvořen alespoň jeden materializovaný pohled patřící druhému členu týmu a používající tabulky definované prvním
-- členem týmu (nutno mít již definována přístupová práva), vč. SQL příkazů/dotazů ukazujících, jak
-- materializovaný pohled funguje,