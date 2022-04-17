
-- ###### dva dotazy využívající spojení dvou tabulek ######
-- Zobrazenie podrobností o účte (účet/typ)
SeLECT ACCOUNT_NUMBER, IBAN, BALANCE, IS_ACTIVE, TYPE_NAME, MANAGEMENT_FEE
    FROM account NATURAL JOIN account_type;

-- Zobrazenie podrobností o platobnej karte (karta/typ karty)s
SELECT CARD_NUMBER, EXPIRATION_DATE, CARD_TYPE.NAME as CARD_TYPE, COMPANY
    FROM payment_card NATURAL JOIN card_type;

-- ###### jeden využívající spojení tří tabulek ########
-- Zobrazenie informácii o človeku.
SELECT FIRST_NAME, LAST_NAME, PERSON_ID, GENDER, DATE_OF_BIRTH, PHONE_NUMBER, EMAIL, ADDRESS, CITY, COUNTRY, POSTAL_CODE
    FROM person NATURAL JOIN place NATURAL JOIN contact_info;

-- ###### dva dotazy s klauzulí GROUP BY a agregační funkcí #######
-- Počet rôznych typov účtov
SELECT TYPE_NAME, COUNT(*) as Accounts_count FROM ACCOUNT_TYPE GROUP BY TYPE_NAME;

-- Počet vydaných kariet jednotlivými spoločnosťami.
SELECT COMPANY, COUNT(*) as CARDS_COUNT FROM CARD_TYPE GROUP BY COMPANY;

-- ###### jeden dotaz obsahující predikát EXISTS ######
-- Zobrazenie služieb aktívnych účtov
SELECT NAME, DESCRIPTION, FEE
    FROM SERVICE WHERE EXISTS(
        SELECT ACCOUNT_NUMBER FROM ACCOUNT
        JOIN ACCOUNT_SERVICE AccService on ACCOUNT.ACCOUNT_ID = AccService.ACCOUNT_ID
        WHERE SERVICE.SERVICE_ID = AccService.SERVICE_ID AND IS_ACTIVE = 1);

-- ###### jeden dotaz s predikátem IN s vnořeným selectem (nikoliv IN s množinou konstantních dat) #######
-- Zobrazenie základných informácií o zamestnancoch banky, ktorá má id nižšie ako 2
SELECT FIRST_NAME, LAST_NAME, PERSONAL_ID, WORK_POSITION, SALARY FROM PERSON
    JOIN EMPLOYEE ON PERSON.PERSON_ID = EMPLOYEE.PERSON_ID
    JOIN BRANCH ON EMPLOYEE.BRANCH_ID = BRANCH.BRANCH_ID
    JOIN BANK ON BANK.BANK_ID = BRANCH.BANK_ID
    WHERE BANK.NAME IN (SELECT NAME FROM BANK WHERE BANK.BANK_CODE > 6000);