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
        FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
            EXECUTE IMMEDIATE ('DROP SEQUENCE ' || s.sequence_name);
        END LOOP;
        FOR i IN 1..array.count LOOP
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

CREATE TABLE person (
    person_id int primary key,
    first_name varchar(255) CHECK (regexp_like(first_name,'^[[:alpha:]]+$')),
    last_name varchar(255) CHECK (regexp_like(last_name,'^[[:alpha:]]+$')),
    personal_id varchar(255) unique CHECK (
        -- After six digits and slash cannot be 000, but can be 0000
        -- If day > 40 then month can only be 0x 1x 5x 6x
        -- If day > 40 then >600 OR >6000
        -- Normal date validation, month can be +20, +50 or +70, day can be +40
        -- If month is 2x 3x 7x or 8x then year must be higher or equal 2004 (year 04 and more and 4 digits after slash)
        -- Check MOD 11 for 10 digits
        regexp_like(personal_id,'^(([0-9]{6})/(([1-9][0-9][0-9]|[0-9][1-9][0-9]|[0-9][0-9][1-9])|([0-9]{4})))$')
        AND (regexp_like(personal_id,'^([0-9]{2}(([1056][0-9][4-9][0-9])|([0-9]{2}[0123][0-9]))/[0-9]{3,4})$')
        AND (regexp_like(personal_id,'^([0-9]{4}(([4-9][0-9]/[6-9][0-9]{2,3})|([0-3][0-9]/[0-9]{3,4})))$')
        AND (regexp_like(personal_id,'^([0-9]{2}(((([0257][13578])|([1368][02]))(([04][1-9])|([1256][0-9])|([37][01])))|((([0257][469])|[1368]1)(([04][1-9])|([1256][0-9])|([37]0)))|([0257]2(([04][1-9])|([15][0-9])|([26][0-8]))))/[0-9]{3,4})$')
        AND (regexp_like(personal_id,'^((((0[4-9])|([1-4][0-9])|(5[0-3]))([2378][0-9]{3})(/[0-9]{4}))|(([0-9]{2})([0156][0-9]{3})(/[0-9]{3,4})))$')
        AND (regexp_like(personal_id, '^[0-9]{6}/[0-9]{4}$') AND MOD(replace(personal_id,'/',''), 11) IN 0
            OR (regexp_like(personal_id, '^[0-9]{6}/[0-9]{3}$')))))))),
    gender char CHECK (gender in ('M', 'F')),
    date_of_birth date,
    place_id int null --FK
);

CREATE TABLE client(
    client_id int primary key
);

CREATE TABLE employee(
    employee_id int primary key,
    work_position varchar(255),
    salary decimal(10, 2),
    holidays_left int,
  started_at date,
    ended_at date,
    branch_id int null --FK
);

CREATE TABLE account(
    account_id int primary key,
    account_number varchar(22) CHECK (regexp_like(account_number,'^[0-9]{6}/[0-9]{10}/[0-9]{4}$')),
    IBAN varchar(30) unique CHECK (regexp_like(IBAN,'^(CZ|SK)[0-9]{22}$')),
    balance decimal(10, 2),
    is_active int CHECK (is_active IN (0, 1)),
    branch_id int null, --FK
    employee_id int null, --FK
    client_user_id int null, --FK
    account_type_id int null, --FK
    currency_id int null --FK
);

CREATE TABLE client_user(
    user_id int primary key,
    username varchar(7) unique CHECK (regexp_like(username, '^[0-9]{7}$')),
    password varchar(128),
    client_id int null --FK
);

CREATE TABLE account_type(
    account_type_id int primary key,
    type_name varchar(255),
    management_fee decimal(10, 2)
);

CREATE TABLE bank(
    bank_id int primary key,
    name varchar(255) unique,
    bank_code varchar(4) unique CHECK (regexp_like(bank_code, '^[0-9]{4}$')),
    ICO varchar(8) unique CHECK (regexp_like(ICO, '^[0-9]{8}$')),
    swift_code varchar(20) unique CHECK (regexp_like(swift_code, '^([A-Z]|[0-9]){8,11}$'))
);

CREATE TABLE branch(
    branch_id int primary key,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    phone_number varchar(13) CHECK (regexp_like(phone_number, '^\+[0-9]{12}$')),
    bank_id int null --FK
);

CREATE TABLE payment_card(
    payment_card_id int primary key,
    card_number varchar(16) unique CHECK(regexp_like(card_number, '^(4[0-9]{12}([0-9]{3})?|5[1-5][0-9]{14})$')),
    expiration_date varchar(5) unique CHECK (regexp_like(expiration_date, '^((1[0-2])|(0[1-9]))/[0-9]{2}$')),
    CVV varchar(3) CHECK (regexp_like(CVV, '^[0-9]{3}$')),
    is_active int CHECK (is_active IN (0, 1)),
    withdrawal_limit decimal(10, 2),
    mo_to_limit decimal(10, 2),
    proximity_payment_limit decimal(10, 2),
    global_payment_limit decimal(10, 2),
    account_id int null, --FK
    card_type_id int null, --FK
    client_user_id int null --FK
);

CREATE TABLE card_type(
    card_type_id int primary key,
    name varchar(255),
    company varchar(255),
    debit_limit decimal (10, 2),
    description varchar(255)
);

CREATE TABLE operation(
    operation_id int primary key,
    operation_type varchar(32) CHECK (operation_type IN ('withdrawal', 'deposit', 'payment')),
    amount decimal(10, 2),
    was_created_at date,
    is_done int CHECK (is_done IN (0, 1)),
    IBAN varchar(30) CHECK (regexp_like(IBAN,'^(CZ|SK)[0-9]{22}$')),
    account_id int null, --FK
    currency_id int null --FK
);

CREATE TABLE currency(
    currency_id int primary key,
    name varchar(40),
    exchange_rate decimal(10, 5)
);

CREATE TABLE place(
    place_id int primary key,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    postal_code varchar(255) CHECK (regexp_like(postal_code, '^[0-9]{5}$'))
);

CREATE TABLE contact_info(
    contact_id int primary key,
    phone_number varchar(13) unique CHECK (regexp_like(phone_number, '^\+[0-9]{12}$')),
    email varchar(255) unique CHECK (regexp_like(email,'^\w{3,}(\.\w+)?@(\w{2,}\.)+\w{2,3}$'))
);

CREATE TABLE service(
    service_id int primary key,
    name varchar(255),
    description varchar(255),
    activation_date date,
    fee decimal(10, 2)
);


-- Create relationship
ALTER TABLE branch ADD(
    CONSTRAINT fk_place_branch FOREIGN KEY (branch_id) REFERENCES place (place_id) ON DELETE CASCADE,
    CONSTRAINT fk_contact_branch FOREIGN KEY (branch_id) REFERENCES contact_info (contact_id) ON DELETE CASCADE,
    CONSTRAINT fk_bank_branch FOREIGN KEY (bank_id) REFERENCES bank (bank_id) ON DELETE CASCADE
    );

ALTER TABLE client ADD (
    CONSTRAINT fk_person_client FOREIGN KEY (client_id) REFERENCES person (person_id) ON DELETE CASCADE
    );

ALTER TABLE employee ADD (
    CONSTRAINT fk_person_employee FOREIGN KEY (employee_id) REFERENCES person (person_id) ON DELETE CASCADE,
    CONSTRAINT fk_branch_employee FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON DELETE CASCADE
    );

ALTER TABLE person ADD (
    CONSTRAINT fk_contact_person FOREIGN KEY (person_id) REFERENCES contact_info (contact_id) ON DELETE CASCADE,
    CONSTRAINT fk_place_person FOREIGN KEY (place_id) REFERENCES place (place_id) ON DELETE CASCADE
    );

ALTER TABLE account ADD (
    CONSTRAINT fk_branch_account FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON DELETE CASCADE,
    CONSTRAINT fk_employee_account FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE CASCADE,
    CONSTRAINT fk_clientUser_account FOREIGN KEY (client_user_id) REFERENCES client_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_accType_account FOREIGN KEY (account_type_id) REFERENCES account_type (account_type_id) ON DELETE CASCADE,
    CONSTRAINT fk_currency_account FOREIGN KEY (currency_id) REFERENCES currency (currency_id) ON DELETE CASCADE
    );

ALTER TABLE client_user ADD (
    CONSTRAINT fk_client_clientUser FOREIGN KEY (client_id) REFERENCES client (client_id) ON DELETE CASCADE
    );

ALTER TABLE payment_card ADD (
    CONSTRAINT fk_account_paymentCard FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE,
    CONSTRAINT fk_cardType_paymentCard FOREIGN KEY (card_type_id) REFERENCES card_type (card_type_id) ON DELETE CASCADE,
    CONSTRAINT fk_clientUser_paymentCard FOREIGN KEY (client_user_id) REFERENCES client_user (user_id) ON DELETE CASCADE
    );

ALTER TABLE operation ADD (
    CONSTRAINT fk_account_operation FOREIGN KEY (account_id) REFERENCES account (account_id) ON DELETE CASCADE,
    CONSTRAINT fk_currency_operation FOREIGN KEY (currency_id) REFERENCES currency (currency_id) ON DELETE CASCADE
    );

-- Helping tables
CREATE TABLE account_service (
    id int primary key,
    account_id int,
    service_id int,
    CONSTRAINT fk_account_accountService FOREIGN KEY (account_id) REFERENCES account (account_id),
    CONSTRAINT fk_service_accountService FOREIGN KEY (service_id) REFERENCES service (service_id)
);

CREATE TABLE rules (
    id int primary key,
    daily_limit int not null,
    account_id int,
    client_user_id int,
    CONSTRAINT fk_account_rules FOREIGN KEY (account_id) REFERENCES account (account_id),
    CONSTRAINT fk_clientUser_rules FOREIGN KEY (client_user_id) REFERENCES client_user (user_id)
);

-- Insert data
INSERT INTO place VALUES (SEQ_PLACE_ID.nextval, 'Božetěchova 2', 'Brno', 'Czechia', '61200');
INSERT INTO place VALUES (SEQ_PLACE_ID.nextval, 'Vrázova 973', 'Prague', 'Czechia', '15000');
INSERT INTO place VALUES (SEQ_PLACE_ID.nextval, 'Krátka 6', 'Bratislava', 'Slovakia', '81103');
INSERT INTO place VALUES (SEQ_PLACE_ID.nextval, 'Brezová 483', 'Košice', 'Slovakia', '04001');
INSERT INTO place VALUES (SEQ_PLACE_ID.nextval, 'Polská 1', 'Olomouc', 'Czechia', '77900');

INSERT INTO contact_info VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420734916785', 'ondrej.novak@mail.com');
INSERT INTO contact_info VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420600435980', 'novak.andrej123@gmail.com');
INSERT INTO contact_info VALUES (SEQ_CONTACT_INFO_ID.nextval, '+420550604800', 'suchaa@seznam.cz');
INSERT INTO contact_info VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421723014059', '681455@fit.vutbr.cz');
INSERT INTO contact_info VALUES (SEQ_CONTACT_INFO_ID.nextval, '+421639822019', 'marian1@email.cz');

INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Ondřej', 'Novák', '010710/2831', 'M', '10.7.2001', 1);
INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Andrej', 'Novák', '510527/371', 'M', '27.5.1951', 1);
INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Anna', 'Suchá', '045111/6996', 'F', '11.1.2004', 2);
INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Mária', 'Horváthová', '315216/557', 'F', '16.2.1931', 3);
INSERT INTO person VALUES (SEQ_PERSON_ID.nextval, 'Marián', 'Mráz', '861219/9761', 'M', '19.12.1986', 4);

INSERT INTO currency VALUES(SEQ_CURRENCY_ID.nextval, 'EUR', 1);
INSERT INTO currency VALUES(SEQ_CURRENCY_ID.nextval, 'CZK', 0.040);
INSERT INTO currency VALUES(SEQ_CURRENCY_ID.nextval, 'USD', 0.89);
INSERT INTO currency VALUES(SEQ_CURRENCY_ID.nextval, 'JPY', 0.0077);
INSERT INTO currency VALUES(SEQ_CURRENCY_ID.nextval, 'BTC', 36618.24);

INSERT INTO account_type VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Checking Account', '0');
INSERT INTO account_type VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Savings Account', '0');
INSERT INTO account_type VALUES (SEQ_ACCOUNT_TYPE_ID.nextval, 'Market Deposit Account', '400');

INSERT INTO card_type VALUES (SEQ_CARD_TYPE_ID.nextval, 'VISA standard', 'VISA', 1000, 'Standart VISA card');
INSERT INTO card_type VALUES (SEQ_CARD_TYPE_ID.nextval, 'VISA premium', 'VISA', 0, 'VISA card for premium account');
INSERT INTO card_type VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard standard', 'MasterCard', 1000, 'Standart MasterCard card');
INSERT INTO card_type VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard premium', 'MasterCard', 10000, 'Premium MasterCard card') ;
INSERT INTO card_type VALUES (SEQ_CARD_TYPE_ID.nextval, 'MasterCard platinum', 'MasterCard', 0, 'Platinum MasterCard card');

INSERT INTO bank VALUES (SEQ_BANK_ID.nextval, 'Equa bank a.s.', '6100', '47116102', 'EQBKCZPP');
INSERT INTO bank VALUES (SEQ_BANK_ID.nextval, 'Home Credit a.s.', '6000', '26978636', 'HCFBRUMM');
INSERT INTO bank VALUES (SEQ_BANK_ID.nextval, 'Fio banka, a.s.', '2010', '61858374', 'FIOBCZPP');
INSERT INTO bank VALUES (SEQ_BANK_ID.nextval, 'Slovenská sporitelna, a.s.', '0900', '00151653', 'GIBASKBX');
INSERT INTO bank VALUES (SEQ_BANK_ID.nextval, 'mBank S.A.', '6210', '27943445', 'BREXCZPP');

INSERT INTO branch VALUES (SEQ_BRANCH_ID.nextval, 'Joštova 137', 'Brno', 'Czechia', '+420222010540', 1);
INSERT INTO branch VALUES (SEQ_BRANCH_ID.nextval, 'Nevädzová 6', 'Bratislava', 'Slovakia', '+421850638171', 2);
INSERT INTO branch VALUES (SEQ_BRANCH_ID.nextval, 'Hlavná 8', 'Košice', 'Slovakia', '+421220850438', 3);
INSERT INTO branch VALUES (SEQ_BRANCH_ID.nextval, 'Námestie slobody 24', 'Skalica', 'Slovakia', '+421850111888', 4);
INSERT INTO branch VALUES (SEQ_BRANCH_ID.nextval, 'Polská 1', 'Olomouc', 'Czechia', '+420585757003', 5);

INSERT INTO employee VALUES (SEQ_EMPLOYEE_ID.nextval, 'Director', 4500, 0, '1.7.2005', '20.3.2009', 1);
INSERT INTO employee VALUES (SEQ_EMPLOYEE_ID.nextval, 'Director', 4800, 22, '21.3.2009', null, 1);
INSERT INTO employee VALUES (SEQ_EMPLOYEE_ID.nextval, 'Manager', 3000, 10, '31.1.2019', null, 2);
INSERT INTO employee VALUES (SEQ_EMPLOYEE_ID.nextval, 'Financial Advisor', 2200, 2, '6.6.2018', null, 4);
INSERT INTO employee VALUES (SEQ_EMPLOYEE_ID.nextval, 'Personal banker', 1520, 15, '1.5.2022', null, 3);

INSERT INTO client VALUES (SEQ_CLIENT_ID.nextval);
INSERT INTO client VALUES (SEQ_CLIENT_ID.nextval);
INSERT INTO client VALUES (SEQ_CLIENT_ID.nextval);
INSERT INTO client VALUES (SEQ_CLIENT_ID.nextval);
INSERT INTO client VALUES (SEQ_CLIENT_ID.nextval);

INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '1121649', '2568a7f8c522e81121f2adc91bd8fc8f9a7ce063a83580829528f3f2d17fb0b8', 1);
INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '2209634', '2568a7f8c522e81121f2adc91bd8fc8f9a7ce063a83580829528f3f2d17fb0b8', 1);
INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '1136925', 'b136aaeddc0c37ed03158551378dca895834d1cef68d642dafea4251ae8480dd', 2);
INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '1963482', 'abf67d1bc217bba7fd014b91f24009c9bc177ef6675b7480d4839f1d8815b81f', 3);
INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '1682334', 'd566c130da1011180b3584e22d60dd0cfae250fa1e030bfa68cce593a1efa9f1', 4);
INSERT INTO client_user VALUES (SEQ_CLIENT_USER_ID.nextval, '1210801', '4a3ca91f11c4ade33cca71eabf4f179a9f74f05b09367612256aa9428bcf602e', 5);

INSERT INTO account VALUES (SEQ_ACCOUNT_ID.nextval, '000000/1030432706/6100', 'CZ7661000000001030432706', 531.20, 1, 1, 4, 1, 1, 2);
INSERT INTO account VALUES (SEQ_ACCOUNT_ID.nextval, '670100/2216739313/6210', 'CZ5262106701002216739313', 2999.00, 0, 5, 3, 2, 1, 2);
INSERT INTO account VALUES (SEQ_ACCOUNT_ID.nextval, '000000/5134779323/0900', 'SK4709000000005134779323', 150020.90, 0, 4, 4, 1, 1, 1);

INSERT INTO payment_card VALUES (SEQ_PAYMENT_CARD_ID.nextval, '4801769871971639', '07/25', '656', 1, 10000.00, 10000.00, 10000.00, 40000.00, 3, 5, 1);
INSERT INTO payment_card VALUES (SEQ_PAYMENT_CARD_ID.nextval, '5349804471300347', '04/28', '908', 1, 100.00, 0.00, 100.00, 200.00, 1, 1, 1);
INSERT INTO payment_card VALUES (SEQ_PAYMENT_CARD_ID.nextval, '5495677450052911', '09/22', '679', 1, 2000.00, 0.00, 0.00, 2000.00, 2, 1, 2);

INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'withdrawal', 100.00, '5.6.2021', 1, null, 3, 3);
INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'withdrawal', 20000.00, '6.8.2021', 1, null, 2, 4);
INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'deposit', 500.00, '10.12.2021', 1, null, 1, 2);
INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'deposit', 300.00, '10.1.2022', 1, 'SK4709000000005134779323', 1, 1);
INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'payment', 1350.00, '1.1.2022', 0, 'SK4709000000005134779323', 3, 1);
INSERT INTO operation VALUES (SEQ_OPERATION_ID.nextval, 'payment', 59.99, '12.1.2022', 0, 'CZ5262106701002216739313', 2, 2);

COMMIT;