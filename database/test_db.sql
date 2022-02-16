-- DROP all custom tables that exists
-- -942 == trying to drop non-existing table -> ignoring exception
-- if the DROP fails for some other reason -> the exception is still raised

BEGIN
    DECLARE
        type array_t is varray(40) of varchar2(100);
        array array_t := array_t(
            'person', 'client', 'employee', 'account', 'account_type', 'bank', 'branch', 'payment_card',
            'client_user', 'card_type', 'operation', 'place', 'contact_info', 'service', 'currency'
            );
        BEGIN
        FOR i IN 1..array.count LOOP
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
    personal_id varchar(255) unique CHECK (regexp_like(personal_id,'^\d{6}/\d{4}$')),
    sex char CHECK (sex in ('M', 'F')),
    date_of_birth date
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
    ended_at date
);

CREATE TABLE account(
    account_id int primary key,
    account_number varchar(22) unique,
    IBAN varchar(30) unique,
    balance decimal(10, 2),
    is_active int CHECK ( is_active IN (0, 1))
);

CREATE TABLE client_user(
    user_id int primary key,
    username varchar(32),
    password varchar(32)
);

CREATE TABLE account_type(
    account_type_id int primary key,
    type_name varchar(255),
    management_fee decimal(10, 2)
);

CREATE TABLE bank(
    bank_id int primary key,
    name varchar(255) unique,
    bank_code int unique,
    ICO int unique,
    swift_code varchar(20) unique
);

CREATE TABLE branch(
    branch_id int primary key,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    phone_number varchar(10) CHECK (regexp_like(phone_number, '^\d{9}$'))
);

CREATE TABLE payment_card(
    payment_card_id int primary key,
    card_number varchar(16) unique,
    expiration_date varchar(5) unique,
    CVV varchar(3),
    is_active int CHECK ( is_active IN (0, 1)),
    withdrawal_limit decimal(10, 2),
    mo_to_limit decimal(10, 2),
    proximity_payment_limit decimal(10, 2),
    global_payment_limit decimal(10, 2)
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
    operation_type varchar(32),
    amount decimal(10, 2),
    was_created_at date,
    is_done int CHECK ( is_done IN (0, 1) ),
    IBAN varchar(30)
);

CREATE TABLE currency(
    currency_id int primary key,
    name varchar(40),
    exchange_rate decimal(10,5)
);

CREATE TABLE place(
    place_id int primary key,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    postal_code integer CHECK (regexp_like(postal_code, '^\d{5}$'))
);

CREATE TABLE contact_info(
    contact_id int primary key,
    phone_number varchar(10) unique CHECK (regexp_like(phone_number, '^\d{9}$')),
    email varchar(255) unique CHECK (regexp_like(email,'^c /^\S+@\S+\.\S+$/'))
);

CREATE TABLE service(
    service_id int primary key,
    name varchar(255),
    description varchar(255),
    activation_date date,
    fee decimal(10, 2)
);

INSERT INTO person VALUES (0, 'Ondřej', 'Novák', '010203/1234', 'M', '3.2.2001');
INSERT INTO person VALUES (1, 'Anna', 'Suchá', '010263/4567', 'F', '3.2.2001');
INSERT INTO person VALUES (2, 'Antonín', 'Novák', '030204/1111', 'M', '4.2.2003');
INSERT INTO place VALUES (0, 'adr0', 'Čobolo city', 'Slovakia','63500');
INSERT INTO client VALUES (0);
INSERT INTO client VALUES (1);
INSERT INTO client VALUES (2);
INSERT INTO employee VALUES (0, 'position_list', 42000.00, 0, '1.1.2020', null);
INSERT INTO employee VALUES (1, 'position_list', 69000, 42, '2.2.2020', '3.2.2022');
INSERT INTO account VALUES (0, '1245/0000164548/6100', '123456489790', 15422.03, 1);
INSERT INTO account VALUES (1, '1245/0000164549/6100', '6546546546546', 0.03, 0);
INSERT INTO currency VALUES(0, 'EUR', 1);
INSERT INTO currency VALUES(1, 'CZK', 0.041);
INSERT INTO client_user VALUES (0, 'turbomost', 'heslo123');
INSERT INTO client_user VALUES (1, 'blackwolf', 'IFJ_is_easy');
INSERT INTO account_type VALUES (0, 'bezny', '0');
INSERT INTO account_type VALUES (1, 'sporici', '0');
INSERT INTO account_type VALUES (2, 'platinum', '1000');
INSERT INTO bank VALUES (0, 'Equa bank', '6100', '12345678', 'EKOPHSUI');
INSERT INTO bank VALUES (1, 'KB', '6600', '11223344', 'WAUZGR');
INSERT INTO branch VALUES (0, 'branch_adr', 'Brno', 'Czechia', '123456789');
INSERT INTO branch VALUES (1, 'branch_adr_2', 'Brno', 'Czechia', '123456778');
INSERT INTO payment_card VALUES (0, '0000111122223333', '01/23', '123', 1, null, null, null, null);
INSERT INTO payment_card VALUES (1, '0000111122224444', '01/22', '123', 0, 69000.00, 69000.00, 69000.00, 69000.00);
INSERT INTO card_type VALUES (0, 'VISA standard', 'VISA', 0, 'ahoj');
INSERT INTO card_type VALUES (1, 'VISA gold', 'VISA', 2000.00, 'gold club');
INSERT INTO card_type VALUES (2, 'MasterCard standard', 'MasterCard', 0, 'pleb club');
INSERT INTO operation VALUES (0, 'op_type_list', 123.00, '1.1.2022', 0, 'CZ0212345678351');

COMMIT;