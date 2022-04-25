-- vytvoření alespoň dvou netriviálních databázových triggerů vč. jejich předvedení


-- vytvoření alespoň dvou netriviálních uložených procedur vč. jejich předvedení,
-- ve kterých se musí (dohromady) vyskytovat alespoň jednou kurzor,
-- ošetření výjimek a použití proměnné s datovým typem odkazujícím se na řádek či
-- typ sloupce tabulky (table_name.column_name%TYPE nebo table_name%ROWTYPE),

CREATE OR REPLACE PROCEDURE CHANGE_DEBITS_LIMITS_BY_COMPANY(cardCompany varchar, debitLimit number)
    IS
    card_id CARD_TYPE.CARD_TYPE_ID%type;
    CURSOR select_cards IS SELECT CARD_TYPE_ID
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
    CURSOR select_salary IS SELECT SALARY, EMPLOYEE_ID
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


-- vytvořen alespoň jeden materializovaný pohled patřící druhému členu týmu a používající tabulky definované prvním
-- členem týmu (nutno mít již definována přístupová práva), vč. SQL příkazů/dotazů ukazujících, jak
-- materializovaný pohled funguje,