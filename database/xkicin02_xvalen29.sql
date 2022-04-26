-- DROP all custom tables that exists from declared array
-- DROP all sequences from user_sequences
-- Create all custom sequences from the array
BEGIN
    DECLARE
        type array_t is varray(40) of varchar2(100);
        array array_t := array_t(
                'person', 'client', 'employee', 'account', 'account_type', 'bank', 'branch', 'payment_card',
                'client_user', 'card_type', 'operation', 'place', 'contact_info', 'service', 'currency',
                'rules', 'account_service'
            );
    BEGIN
        FOR s IN (SELECT sequence_name FROM user_sequences)
            LOOP
                EXECUTE IMMEDIATE ('DROP SEQUENCE ' || s.sequence_name);
            END LOOP;
        FOR i IN 1..array.count
            LOOP
                EXECUTE IMMEDIATE ('CREATE SEQUENCE seq_' || array(i) || '_id');
                BEGIN
                    EXECUTE IMMEDIATE ('DROP TABLE ' || array(i) || ' CASCADE CONSTRAINTS');
                EXCEPTION
                    WHEN OTHERS THEN
                        IF SQLCODE != -942 THEN
                            RAISE;
                        END IF;
                END;
            END LOOP;
    END;
END;
/
---------------------
--- CREATE TABLES ---
---------------------
CREATE TABLE person
(
    person_id     int primary key,
    first_name    varchar(255) CHECK (regexp_like(first_name, '^[[:alpha:]]+$'))             not null,
    last_name     varchar(255) CHECK (regexp_like(last_name, '^[[:alpha:]]+$'))              not null,
    personal_id   varchar(255) unique CHECK (

        -- After six digits and slash cannot be 000, but can be 0000
        -- If day > 40 then month can only be 0x 1x 5x 6x
        -- If day > 40 then last digits >=600 OR >=6000
        -- Normal date validation (day and month combination), month can be +20, +50 or +70, day can be +40
        -- Leap year validation for february (if year is 2000 or multiple of 4 but not multiple of 100)
        -- If month is 2x 3x 7x or 8x then year must be higher or equal 2004 (year 04 and more and 4 digits after slash)
        -- If 10 digits then check if mod 11 = 0 OR if mod 11 of substring is 10 and last digit is 0

            regexp_like(personal_id, '^(([0-9]{6})/(([1-9][0-9][0-9]|[0-9][1-9][0-9]|[0-9][0-9][1-9])|([0-9]{4})))$')
            AND (regexp_like(personal_id, '^([0-9]{2}(([1056][0-9][4-9][0-9])|([0-9]{2}[0123][0-9]))/[0-9]{3,4})$')
            AND (regexp_like(personal_id, '^([0-9]{4}(([4-9][0-9]/[6-9][0-9]{2,3})|([0-3][0-9]/[0-9]{3,4})))$')
                AND ((regexp_like(personal_id,
                                  '^([0-9]{2}(((([0257][13578])|([1368][02]))(([04][1-9])|([1256][0-9])|([37][01])))|((([0257][469])|[1368]1)(([04][1-9])|([1256][0-9])|([37]0)))|([0257]2(([04][1-9])|([15][0-9])|([26][0-8]))))/[0-9]{3,4})$')
                    OR (regexp_like(personal_id,
                                    '^(00[0257]2[26]9/[0-9]{4})|(((0[48]|[2468][048])|([13579][26]))0229/[0-9]{3,4})$')))
                    AND ((regexp_like(personal_id,
                                      '^((((0[4-9])|([1-4][0-9])|(5[0-3]))([2378][0-9]{3})(/[0-9]{4}))|(([0-9]{2})([0156][0-9]{3})(/[0-9]{3,4})))$')
                        AND ((regexp_like(personal_id, '^[0-9]{6}/[0-9]{4}$') AND
                              MOD(replace(personal_id, '/', ''), 11) IN 0)
                            OR ((regexp_like(personal_id, '^[0-9]{6}/[0-9]{3}0$') AND
                                 MOD(SUBSTR(replace(personal_id, '/', ''), 1, 9), 11) IN 10)
                                OR (regexp_like(personal_id, '^[0-9]{6}/[0-9]{3}$')))))))))) not null,
    gender        char CHECK (gender in ('M', 'F')),
    date_of_birth date,
    place_id      int, --FK
    contact_id    int  --FK
);

CREATE TABLE client
(
    client_id int primary key,
    person_id int --FK
);

CREATE TABLE employee
(
    employee_id   int primary key,
    work_position varchar(255),
    salary        decimal(10, 2),
    holidays_left int,
    started_at    date,
    ended_at      date,
    branch_id     int, --FK
    person_id     int  --FK
);

CREATE TABLE account
(
    account_id      int primary key,
    account_number  varchar(22) CHECK (regexp_like(account_number, '^([0-9]{6}/)?[0-9]{10}/[0-9]{4}$')) not null,
    IBAN            varchar(30) unique CHECK (regexp_like(IBAN, '^(CZ|SK)[0-9]{22}$')),
    balance         decimal(10, 2),
    is_active       int CHECK (is_active IN (0, 1))                                                     not null,
    branch_id       int, --FK
    employee_id     int, --FK
    user_id         int, --FK
    account_type_id int, --FK
    currency_id     int  --FK
);

CREATE TABLE client_user
(
    user_id   int primary key,
    username  varchar(7) unique CHECK (regexp_like(username, '^[0-9]{7}$')) not null,
    password  varchar(128),
    client_id int --FK
);

CREATE TABLE account_type
(
    account_type_id int primary key,
    type_name       varchar(255),
    management_fee  decimal(10, 2)
);

CREATE TABLE bank
(
    bank_id    int primary key,
    name       varchar(255) unique,
    bank_code  varchar(4) unique CHECK (regexp_like(bank_code, '^[0-9]{4}$')),
    ICO        varchar(8) unique CHECK (regexp_like(ICO, '^[0-9]{8}$')) not null,
    swift_code varchar(20) unique CHECK (regexp_like(swift_code, '^([A-Z]{4}(CZ|SK)([0-9]|[A-Z]){2})$'))
);

CREATE TABLE branch
(
    branch_id  int primary key,
    bank_id    int DEFAULT 1, --FK
    place_id   int,           --FK
    contact_id int            --FK
);

CREATE TABLE payment_card
(
    payment_card_id         int primary key,
    card_number             varchar(16) unique CHECK (regexp_like(card_number, '^(4[0-9]{12}([0-9]{3})?|5[1-5][0-9]{14})$')) not null,
    expiration_date         varchar(5) unique CHECK (regexp_like(expiration_date, '^((1[0-2])|(0[1-9]))/[0-9]{2}$'))         not null,
    CVV                     varchar(3) CHECK (regexp_like(CVV, '^[0-9]{3,4}$'))                                              not null,
    is_active               int CHECK (is_active IN (0, 1))                                                                  not null,
    withdrawal_limit        decimal(10, 2),
    mo_to_limit             decimal(10, 2),
    proximity_payment_limit decimal(10, 2),
    global_payment_limit    decimal(10, 2),
    account_id              int, --FK
    card_type_id            int, --FK
    user_id                 int  --FK
);

CREATE TABLE card_type
(
    card_type_id int primary key,
    name         varchar(255),
    company      varchar(255),
    debit_limit  decimal(10, 2),
    description  varchar(255)
);

CREATE TABLE operation
(
    operation_id   int primary key,
    operation_type varchar(32) CHECK (operation_type IN ('withdrawal', 'deposit', 'payment')) not null,
    amount         decimal(10, 2),
    create_date    date,
    processed_date date,
    finished_date  date,
    is_done        int CHECK (is_done IN (0, 1)),
    IBAN           varchar(30) CHECK (regexp_like(IBAN, '^(CZ|SK)[0-9]{22}$')),
    account_id     int, --FK
    currency_id    int, --FK
    user_id        int  --FK
);

CREATE TABLE currency
(
    currency_id   int primary key,
    name          varchar(40),
    exchange_rate decimal(10, 5) not null
);

CREATE TABLE place
(
    place_id    int primary key,
    address     varchar(255) not null,
    city        varchar(255),
    country     varchar(255) not null,
    postal_code varchar(255) CHECK (regexp_like(postal_code, '^[0-9]{5}$'))
);

CREATE TABLE contact_info
(
    contact_id   int primary key,
    phone_number varchar(13) unique CHECK (regexp_like(phone_number, '^((\+)?[0-9]{3})?[0-9]{9}$')) not null,
    email        varchar(255) unique CHECK (regexp_like(email, '^\w{3,}(\.\w+)?@(\w{2,}\.)+\w{2,3}$'))
);

CREATE TABLE service
(
    service_id  int primary key,
    name        varchar(255),
    description varchar(255),
    fee         decimal(10, 2)
);


----------------------------
--- CREATE RELATIONSHIPS ---
----------------------------
ALTER TABLE branch
    ADD(
        CONSTRAINT fk_place_branch FOREIGN KEY (place_id) REFERENCES place (place_id) ON DELETE CASCADE,
        CONSTRAINT fk_contact_branch FOREIGN KEY (contact_id) REFERENCES contact_info (contact_id) ON DELETE CASCADE,
        CONSTRAINT fk_bank_branch FOREIGN KEY (bank_id) REFERENCES bank (bank_id) ON DELETE CASCADE
        );

ALTER TABLE client
    ADD (
        CONSTRAINT fk_person_client FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASCADE
        );

ALTER TABLE employee
    ADD (
        CONSTRAINT fk_person_employee FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASCADE,
        CONSTRAINT fk_branch_employee FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON DELETE CASCADE
        );

ALTER TABLE person
    ADD (
        CONSTRAINT fk_contact_person FOREIGN KEY (contact_id) REFERENCES contact_info (contact_id) ON DELETE CASCADE,
        CONSTRAINT fk_place_person FOREIGN KEY (place_id) REFERENCES place (place_id) ON DELETE CASCADE
        );

ALTER TABLE account
    ADD (
        CONSTRAINT fk_branch_account FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON DELETE CASCADE,
        CONSTRAINT fk_employee_account FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE CASCADE,
        CONSTRAINT fk_clientUser_account FOREIGN KEY (user_id) REFERENCES client_user (user_id) ON DELETE CASCADE,
        CONSTRAINT fk_accType_account FOREIGN KEY (account_type_id) REFERENCES account_type (account_type_id) ON DELETE CASCADE,
        CONSTRAINT fk_currency_account FOREIGN KEY (currency_id) REFERENCES currency (currency_id) ON DELETE CASCADE
        );

ALTER TABLE client_user
    ADD (
        CONSTRAINT fk_client_clientUser FOREIGN KEY (client_id) REFERENCES client (client_id) ON DELETE CASCADE
        );

ALTER TABLE payment_card
    ADD (
        CONSTRAINT fk_account_paymentCard FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE,
        CONSTRAINT fk_cardType_paymentCard FOREIGN KEY (card_type_id) REFERENCES card_type (card_type_id) ON DELETE CASCADE,
        CONSTRAINT fk_clientUser_paymentCard FOREIGN KEY (payment_card_id) REFERENCES client_user (user_id) ON DELETE CASCADE
        );

ALTER TABLE operation
    ADD (
        CONSTRAINT fk_account_operation FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE,
        CONSTRAINT fk_currency_operation FOREIGN KEY (currency_id) REFERENCES currency (currency_id) ON DELETE CASCADE,
        CONSTRAINT fk_user_operation FOREIGN KEY (user_id) REFERENCES client_user (user_id) ON DELETE CASCADE
        );

-------------------------------
--- CREATE AUXILIARY TABLES ---
-------------------------------
CREATE TABLE account_service
(
    id              int primary key,
    account_id      int,
    service_id      int,
    activation_date date,
    CONSTRAINT fk_account_accountService FOREIGN KEY (account_id) REFERENCES account (account_id),
    CONSTRAINT fk_service_accountService FOREIGN KEY (service_id) REFERENCES service (service_id)
);

CREATE TABLE rules
(
    id          int primary key,
    daily_limit int not null,
    account_id  int,
    user_id     int,
    CONSTRAINT fk_account_rules FOREIGN KEY (account_id) REFERENCES account (account_id),
    CONSTRAINT fk_clientUser_rules FOREIGN KEY (user_id) REFERENCES client_user (user_id)
);

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

-------------------
--- INSERT DATA ---
-------------------
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Božetěchova 2', 'Brno', 'Czechia', '61200');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Vrázova 973', 'Prague', 'Czechia', '15000');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Krátka 6', 'Bratislava', 'Slovakia', '81103');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Brezová 483', 'Košice', 'Slovakia', '04001');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Polská 1', 'Olomouc', 'Czechia', '77900');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Joštova 137', 'Brno', 'Czechia', '60200');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Nevädzová 6', 'Bratislava', 'Slovakia', '82101');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Hlavná 8', 'Košice', 'Slovakia', '04001');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Námestie slobody 24', 'Skalica', 'Slovakia', '90901');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Kubíčkova 5', 'Brno', 'Czechia', '63500');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Plevova 9', 'Brno', 'Czechia', '61600');
INSERT INTO place
VALUES (SEQ_PLACE_ID.nextval, 'Vejrostova 4', 'Brno', 'Czechia', '63500');

INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420734916785', 'ondrej.novak@mail.com');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '420600435980', 'novak.andrej123@gmail.com');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420550604800', 'suchaa@seznam.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421723014059', '681455@fit.vutbr.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421639822019', 'marian1@email.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '222010540', 'branch1@equa.bank.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '421850638171', 'branch2@equa.bank.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421220850438', 'branch3@equa.bank.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '421850111888', 'branch4@equa.bank.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420585757003', 'branch5@equa.bank.cz');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421911369367', 'kristian.kicinka@gmail.com');
INSERT INTO contact_info
VALUES (SEQ_CONTACT_INFO_ID.nextval, '722034120', 'wasekva@gmail.com');

-- INVALID FORMATS --
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '010724/000', 'M', null, 1);     -- /000
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '012740/6831', 'M', null, 1);    -- Day > 40 but +20 month
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '010740/2831', 'M', null, 1);    -- Day > 40 but last digits < 6000
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '010229/2831', 'M', null, 1);    -- Invalid date 29.02.2001
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '017710/2870', 'M', null, 1);    -- +20 month but year < 2004
--INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '010710/2832', 'M', null, 1);    -- Not divisible by 11

INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '000229/2830', 'M', '29.2.2000', 1, 1);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Andrej', 'Novák', '510527/371', 'M', '27.5.1951', 1, 2);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Anna', 'Suchá', '045111/6996', 'F', '11.1.2004', 2, 3);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Mária', 'Horváthová', '315216/557', 'F', '16.2.1931', 3, 4);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Marián', 'Mráz', '861219/9761', 'M', '19.12.1986', 4, 5);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Kristián', 'Kičinka', '001120/7262', 'M', '20.11.2000', 11, 11);
INSERT INTO person
VALUES (SEQ_PERSON_ID.nextval, 'Václav', 'Valenta', '010724/4071', 'M', '24.07.2001', 12, 12);

INSERT INTO currency
VALUES (SEQ_CURRENCY_ID.nextval, 'EUR', 1);
INSERT INTO currency
VALUES (SEQ_CURRENCY_ID.nextval, 'CZK', 0.040);
INSERT INTO currency
VALUES (SEQ_CURRENCY_ID.nextval, 'USD', 0.89);
INSERT INTO currency
VALUES (SEQ_CURRENCY_ID.nextval, 'JPY', 0.0077);
INSERT INTO currency
VALUES (SEQ_CURRENCY_ID.nextval, 'BTC', 36618.24);

INSERT INTO account_type
VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Checking Account', '0');
INSERT INTO account_type
VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Savings Account', '0');
INSERT INTO account_type
VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Market Deposit Account', '400');

INSERT INTO card_type
VALUES (SEQ_CARD_TYPE_ID.nextval, 'VISA standard', 'VISA', 1000, 'Standart VISA card');
INSERT INTO card_type
VALUES (SEQ_CARD_TYPE_ID.nextval, 'VISA premium', 'VISA', 0, 'VISA card for premium account');
INSERT INTO card_type
VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard standard', 'MasterCard', 1000, 'Standart MasterCard card');
INSERT INTO card_type
VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard premium', 'MasterCard', 10000, 'Premium MasterCard card');
INSERT INTO card_type
VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard platinum', 'MasterCard', 0, 'Platinum MasterCard card');

INSERT INTO bank
VALUES (SEQ_BANK_ID.nextval, 'Equa bank a.s.', '6100', '47116102', 'EQBKCZPP');
INSERT INTO bank
VALUES (SEQ_BANK_ID.nextval, 'Home Credit a.s.', '6000', '26978636', 'PMBPCZPP');
INSERT INTO bank
VALUES (SEQ_BANK_ID.nextval, 'Fio banka, a.s.', '2010', '61858374', 'FIOBCZPP');
INSERT INTO bank
VALUES (SEQ_BANK_ID.nextval, 'Slovenská sporitelna, a.s.', '0900', '00151653', 'GIBASKBX');
INSERT INTO bank
VALUES (SEQ_BANK_ID.nextval, 'mBank S.A.', '6210', '27943445', 'BREXCZPP');

INSERT INTO branch
VALUES (SEQ_BRANCH_ID.nextval, DEFAULT, 6, 6);
INSERT INTO branch
VALUES (SEQ_BRANCH_ID.nextval, DEFAULT, 7, 7);
INSERT INTO branch
VALUES (SEQ_BRANCH_ID.nextval, DEFAULT, 8, 8);
INSERT INTO branch
VALUES (SEQ_BRANCH_ID.nextval, DEFAULT, 9, 9);
INSERT INTO branch
VALUES (SEQ_BRANCH_ID.nextval, DEFAULT, 10, 10);

INSERT INTO employee
VALUES (SEQ_EMPLOYEE_ID.nextval, 'Director', 4500, 0, '1.7.2005', '20.3.2009', 1, 1);
INSERT INTO employee
VALUES (SEQ_EMPLOYEE_ID.nextval, 'Director', 4800, 22, '21.3.2009', null, 1, 2);
INSERT INTO employee
VALUES (SEQ_EMPLOYEE_ID.nextval, 'Manager', 3000, 10, '31.1.2019', null, 2, 3);
INSERT INTO employee
VALUES (SEQ_EMPLOYEE_ID.nextval, 'Financial Advisor', 2200, 2, '6.6.2018', null, 4, 4);
INSERT INTO employee
VALUES (SEQ_EMPLOYEE_ID.nextval, 'Personal banker', 1520, 15, '1.5.2022', null, 3, 5);

INSERT INTO client
VALUES (SEQ_CLIENT_ID.nextval, 1);
INSERT INTO client
VALUES (SEQ_CLIENT_ID.nextval, 2);
INSERT INTO client
VALUES (SEQ_CLIENT_ID.nextval, 3);
INSERT INTO client
VALUES (SEQ_CLIENT_ID.nextval, 4);
INSERT INTO client
VALUES (SEQ_CLIENT_ID.nextval, 5);

INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '1121649', '2568a7f8c522e81121f2adc91bd8fc8f9a7ce063a83580829528f3f2d17fb0b8', 1);
INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '2209634', '2568a7f8c522e81121f2adc91bd8fc8f9a7ce063a83580829528f3f2d17fb0b8', 1);
INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '1136925', 'b136aaeddc0c37ed03158551378dca895834d1cef68d642dafea4251ae8480dd', 2);
INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '1963482', 'abf67d1bc217bba7fd014b91f24009c9bc177ef6675b7480d4839f1d8815b81f', 3);
INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '1682334', 'd566c130da1011180b3584e22d60dd0cfae250fa1e030bfa68cce593a1efa9f1', 4);
INSERT INTO client_user
VALUES (SEQ_CLIENT_USER_ID.nextval, '1210801', '4a3ca91f11c4ade33cca71eabf4f179a9f74f05b09367612256aa9428bcf602e', 5);

INSERT INTO account
VALUES (SEQ_ACCOUNT_ID.nextval, '1030432706/6100', 'CZ7661000000001030432706', 531.20, 1, 1, 4, 1, 1, 2);
INSERT INTO account
VALUES (SEQ_ACCOUNT_ID.nextval, '670100/2216739313/6210', 'CZ5262106701002216739313', 2999.00, 0, 5, 3, 3, 2, 2);
INSERT INTO account
VALUES (SEQ_ACCOUNT_ID.nextval, '000000/5134779323/0900', 'SK4709000000005134779323', 150020.90, 0, 4, 4, 2, 1, 1);

INSERT INTO payment_card
VALUES (SEQ_PAYMENT_CARD_ID.nextval, '4801769871971639', '07/25', '656', 1, 10000.00, 10000.00, 10000.00, 40000.00, 3,
        5, 1);
INSERT INTO payment_card
VALUES (SEQ_PAYMENT_CARD_ID.nextval, '5349804471300347', '04/28', '908', 1, 100.00, 0.00, 100.00, 200.00, 1, 1, 1);
INSERT INTO payment_card
VALUES (SEQ_PAYMENT_CARD_ID.nextval, '5495677450052911', '04/22', '679', 1, 2000.00, 0.00, 0.00, 2000.00, 2, 1, 2);

INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'withdrawal', 100.00, '5.6.2021', '5.6.2021', '5.6.2021', 1, null, 3, 3, 1);
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'withdrawal', 20000.00, '6.8.2021', '6.8.2021', '6.8.2021', 1, null, 2, 4, 5);
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'deposit', 500.00, '10.12.2021', '10.12.2021', '10.12.2021', 1, null, 1, 2, 1);
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'deposit', 300.00, '10.1.2022', '10.1.2022', '11.1.2022', 1,
        'SK4709000000005134779323', 1, 1, 2);
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'payment', 1350.00, '1.1.2022', '1.1.2022', '2.1.2022', 0, 'SK4709000000005134779323',
        3, 1, 2);
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'payment', 1, '12.1.2022', '13.1.2022', '14.1.2022', 0,
        'CZ5262106701002216739313', 2, 5, 3);

INSERT INTO service
VALUES (SEQ_SERVICE_ID.nextval, 'Loan', 'Standard loan', 10);
INSERT INTO service
VALUES (SEQ_SERVICE_ID.nextval, 'Monthly account statement', 'Basic account statement0', 5);
INSERT INTO service
VALUES (SEQ_SERVICE_ID.nextval, 'Overdraft', 'Market account basic overdraft', 20);
INSERT INTO service
VALUES (SEQ_SERVICE_ID.nextval, 'Overdraft premium', 'Market account premium overdraft', 50);

INSERT INTO account_service
VALUES (SEQ_ACCOUNT_SERVICE_ID.nextval, 3, 4, '1.1.2022');
INSERT INTO account_service
VALUES (SEQ_ACCOUNT_SERVICE_ID.nextval, 3, 2, '30.3.2022');
INSERT INTO account_service
VALUES (SEQ_ACCOUNT_SERVICE_ID.nextval, 1, 1, '28.9.2019');
INSERT INTO account_service
VALUES (SEQ_ACCOUNT_SERVICE_ID.nextval, 1, 2, '28.10.2019');
INSERT INTO account_service
VALUES (SEQ_ACCOUNT_SERVICE_ID.nextval, 2, 3, '1.1.2020');

INSERT INTO rules
VALUES (SEQ_RULES_ID.nextval, 100, 1, 1);
INSERT INTO rules
VALUES (SEQ_RULES_ID.nextval, 200, 2, 5);
INSERT INTO rules
VALUES (SEQ_RULES_ID.nextval, 50000, 2, 3);
INSERT INTO rules
VALUES (SEQ_RULES_ID.nextval, 1500, 3, 1);
INSERT INTO rules
VALUES (SEQ_RULES_ID.nextval, 1500, 3, 2);

-----------------------------
--- TRIGGER PRESENTATIONS ---
-----------------------------
-- Card activity trigger presentation
-- Updating expiration date to be overdue
UPDATE PAYMENT_CARD
SET EXPIRATION_DATE = '03/22'
WHERE PAYMENT_CARD_ID = 3;
-- Show all payment cards after activating the trigger
SELECT *
FROM PAYMENT_CARD;

-- Transaction conversion trigger
-- Creating new operation in CZK
INSERT INTO operation
VALUES (SEQ_OPERATION_ID.nextval, 'payment', 59.99, '12.1.2022', '13.1.2022', '14.1.2022', 0,
        'CZ5262106701002216739313', 2, 2, 3);
-- Show all operation after activating the trigger
SELECT *
FROM OPERATION;
---------------
--- SELECTS ---
---------------

-- ###### dva dotazy využívající spojení dvou tabulek ######
-- Zobrazenie základných informacií o účte
-- Číslo účtu, IBAN, zostatok, stav účtu (aktivný / neaktivný), typ účtu, poplatok za vedenie
SELECT ACCOUNT_NUMBER, IBAN, BALANCE, IS_ACTIVE, TYPE_NAME, MANAGEMENT_FEE
FROM account
         NATURAL JOIN account_type;

-- Zobrazenie podrobností o platobnej karte (karta/typ karty)
-- Číslo karty, datum expiracie, typ karty, spoločnosť
SELECT CARD_NUMBER, EXPIRATION_DATE, CARD_TYPE.NAME as CARD_TYPE, COMPANY
FROM payment_card
         NATURAL JOIN card_type;

-- ###### jeden využívající spojení tří tabulek ########
-- Zobrazenie informácii o človeku.
-- Meno, priezvisko, rodné číslo, pohlavie, dátum narodenia, telefonné číslo, email, adresa, mesto, krajina, psč
SELECT FIRST_NAME,
       LAST_NAME,
       PERSONAL_ID,
       GENDER,
       DATE_OF_BIRTH,
       PHONE_NUMBER,
       EMAIL,
       ADDRESS,
       CITY,
       COUNTRY,
       POSTAL_CODE
FROM person
         NATURAL JOIN place
         NATURAL JOIN contact_info;

-- ###### dva dotazy s klauzulí GROUP BY a agregační funkcí #######
-- Počet rôznych typov účtov
SELECT TYPE_NAME, COUNT(*) as Accounts_count
FROM ACCOUNT_TYPE
         NATURAL JOIN ACCOUNT
GROUP BY TYPE_NAME;

-- Počet vydaných kariet jednotlivými spoločnosťami.
SELECT COMPANY, COUNT(*) as CARDS_COUNT
FROM CARD_TYPE
GROUP BY COMPANY;

-- ###### jeden dotaz obsahující predikát EXISTS ######
-- Zobrazenie služieb aktívnych účtov
-- Názov, popis, poplatok za službu
SELECT NAME, DESCRIPTION, FEE
FROM SERVICE
WHERE EXISTS(
              SELECT ACCOUNT_NUMBER
              FROM ACCOUNT
                       JOIN ACCOUNT_SERVICE AccService on ACCOUNT.ACCOUNT_ID = AccService.ACCOUNT_ID
              WHERE SERVICE.SERVICE_ID = AccService.SERVICE_ID
                AND IS_ACTIVE = 1);

-- ###### jeden dotaz s predikátem IN s vnořeným selectem (nikoliv IN s množinou konstantních dat) #######
-- Zobrazenie základných informácií o zamestnancoch banky, ktorá má vyššie kód banky ako 6000
-- Meno, priezvisko, rodné číslo, pozicia, plat
SELECT FIRST_NAME, LAST_NAME, PERSONAL_ID, WORK_POSITION, SALARY
FROM PERSON
         JOIN EMPLOYEE ON PERSON.PERSON_ID = EMPLOYEE.PERSON_ID
         JOIN BRANCH ON EMPLOYEE.BRANCH_ID = BRANCH.BRANCH_ID
         JOIN BANK ON BANK.BANK_ID = BRANCH.BANK_ID
WHERE BANK.NAME IN (SELECT NAME FROM BANK WHERE BANK.BANK_CODE > 6000);

COMMIT;