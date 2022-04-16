
-- ###### dva dotazy využívající spojení dvou tabulek ######
-- Zobrazenie podrobností o účte (účet/typ)
SeLECT ACCOUNT_ID, ACCOUNT_NUMBER, IBAN, BALANCE, IS_ACTIVE, TYPE_NAME, MANAGEMENT_FEE
    FROM account NATURAL JOIN account_type;

-- Zobrazenie podrobností o platobnej karte (karta/typ karty)s
SELECT PAYMENT_CARD_ID, CARD_NUMBER, EXPIRATION_DATE, CARD_TYPE.NAME as CARD_TYPE, COMPANY
    FROM payment_card NATURAL JOIN card_type;

-- ###### jeden využívající spojení tří tabulek ########
-- Zobrazenie informácii o človeku.
SELECT FIRST_NAME,LAST_NAME,PERSON_ID, GENDER, DATE_OF_BIRTH, PHONE_NUMBER, EMAIL, ADDRESS, CITY, COUNTRY, POSTAL_CODE
    FROM person NATURAL JOIN place NATURAL JOIN contact_info;

-- ###### dva dotazy s klauzulí GROUP BY a agregační funkcí #######
-- Počet rôznych typov účtov
SELECT TYPE_NAME, COUNT(*) as Accounts_count FROM ACCOUNT_TYPE GROUP BY TYPE_NAME;

-- Počet vydaných kariet jednotlivými spoločnosťami.
SELECT COMPANY, COUNT(*) as CARDS_COUNT FROM CARD_TYPE GROUP BY COMPANY;

-- ###### jeden dotaz obsahující predikát EXISTS ######
-- Zobrazenie služieb aktívnych účtov
SELECT NAME, DESCRIPTION, FEE
    FROM SERVICE WHERE EXISTS(SELECT ACCOUNT_ID FROM ACCOUNT WHERE IS_ACTIVE = 1);

-- jeden dotaz s predikátem IN s vnořeným selectem (nikoliv IN s množinou konstantních dat)