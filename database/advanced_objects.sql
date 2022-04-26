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

EXPLAIN PLAN FOR
SELECT SERVICE.NAME, SERVICE.FEE, COUNT(A2.ACCOUNT_ID) AS ACCOUNTS_COUNT
FROM SERVICE
         JOIN ACCOUNT_SERVICE "AS" on SERVICE.SERVICE_ID = "AS".SERVICE_ID
         JOIN ACCOUNT A2 on "AS".ACCOUNT_ID = A2.ACCOUNT_ID
GROUP BY SERVICE.NAME, SERVICE.FEE
ORDER BY ACCOUNTS_COUNT DESC;

SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

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

CREATE MATERIALIZED VIEW show_owners_accounts
AS
SELECT USER_ID, PERSON_ID, FIRST_NAME, LAST_NAME, ACCOUNT.ACCOUNT_NUMBER, ACCOUNT.BALANCE
FROM ACCOUNT
         NATURAL JOIN CLIENT_USER
         NATURAL JOIN CLIENT
         NATURAL JOIN PERSON;

CREATE MATERIALIZED VIEW show_disponents_accounts
AS
SELECT DISTINCT CLIENT_USER.USER_ID,
                PERSON_ID,
                FIRST_NAME,
                LAST_NAME,
                ACCOUNT.ACCOUNT_NUMBER,
                ACCOUNT.BALANCE
FROM ACCOUNT
         JOIN RULES ON ACCOUNT.ACCOUNT_ID = RULES.ACCOUNT_ID
         JOIN CLIENT_USER ON RULES.USER_ID = CLIENT_USER.USER_ID
         JOIN CLIENT ON CLIENT_USER.CLIENT_ID = CLIENT.CLIENT_ID
         NATURAL JOIN PERSON;


GRANT ALL ON show_owners_accounts TO XVALEN29;

GRANT ALL ON show_disponents_accounts TO XVALEN29;

SELECT *
FROM show_owners_accounts;

SELECT *
FROM show_disponents_accounts;

DROP MATERIALIZED VIEW show_disponents_accounts;
DROP MATERIALIZED VIEW show_owners_accounts;