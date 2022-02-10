
DROP TABLE person CASCADE CONSTRAINTS;
DROP TABLE client CASCADE CONSTRAINTS;
DROP TABLE employee CASCADE CONSTRAINTS;
DROP TABLE account CASCADE CONSTRAINTS;
DROP TABLE account_type CASCADE CONSTRAINTS;
DROP TABLE bank CASCADE CONSTRAINTS;
DROP TABLE branch CASCADE CONSTRAINTS;
DROP TABLE credit_card CASCADE CONSTRAINTS;
DROP TABLE client_user CASCADE CONSTRAINTS;
DROP TABLE card_type CASCADE CONSTRAINTS;
DROP TABLE operation CASCADE CONSTRAINTS;

CREATE TABLE person (
    person_id int primary key,
    first_name varchar(255) ,
    last_name varchar(255),
    personal_id varchar(255) unique,
    phone_number varchar(10) unique,
    email varchar(255) unique,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    sex char CHECK (sex in ('M', 'F')), -- víme z rodného čísla
    date_of_birth date -- rodné číslo
);

CREATE TABLE client(
    client_id int primary key
);

CREATE TABLE employee(
    employee_id int primary key,
    work_position varchar(255),
    sallary decimal(10, 2),
    holidays_left int,
    started_at date,
    ended_at date
);

CREATE TABLE account(
    account_id int primary key,
    account_number varchar(22) unique,
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
    ICO int unique
);

CREATE TABLE branch(
    branch_id int primary key,
    address varchar(255),
    city varchar(255),
    country varchar(255),
    phone_number varchar(10)
);

CREATE TABLE credit_card(
    credit_card_id int primary key,
    card_number varchar(16) unique,
    expiration_date varchar(5) unique,
    CVV varchar(3),
    is_active int CHECK ( is_active IN (0, 1))
);

CREATE TABLE card_type(
    card_type_id int primary key,
    name varchar(255),
    company varchar(255)
);

CREATE TABLE operation(
    operation_id int primary key,
    operation_type varchar(32),
    amount decimal(10, 2),
    was_created_at date,
    is_done int CHECK ( is_done IN (0, 1) )
);

INSERT INTO person VALUES (0, 'Andrej', 'Novák', '010203/1234', '123456789', 'mail@gmail.com', 'adr0', 'city0', 'Czechia', 'M', '3.2.2001');
INSERT INTO person VALUES (1, 'Anna', 'Suchá', '010263/4567', '234567891', 'mail@seznam.cz', 'adr1', 'city0', 'Czechia', 'F', '3.2.2001');
INSERT INTO person VALUES (2, 'Antonín', 'Novák', '030204/1111', '111222333', 'mail2@gmail.com', 'adr2', 'čobolo city', 'Slovakia', 'M', '4.2.2003');
INSERT INTO client VALUES (0);
INSERT INTO client VALUES (1);
INSERT INTO client VALUES (2);
INSERT INTO employee VALUES (0, 'position_list', 42000.00, 0, '1.1.2020', null);
INSERT INTO employee VALUES (1, 'position_list', 69000, 42, '2.2.2020', '3.2.2022');
INSERT INTO account VALUES (0, '1245/0000164548/6100', 15422.03, 1);
INSERT INTO account VALUES (1, '1245/0000164549/6100', 0.03, 0);
INSERT INTO client_user VALUES (0, 'turbomost', 'heslo123');
INSERT INTO client_user VALUES (1, 'blackwolf', 'ima2easy');
INSERT INTO account_type VALUES (0, 'bezny', '0');
INSERT INTO account_type VALUES (1, 'sporici', '0');
INSERT INTO account_type VALUES (2, 'platinum', '1000');
INSERT INTO bank VALUES (0, 'Equa bank', '6100', '12345678');
INSERT INTO bank VALUES (1, 'KB', '6600', '11223344');
INSERT INTO branch VALUES (0, 'branch_adr', 'Brno', 'Czechia', '123456789');
INSERT INTO credit_card VALUES (0, '0000111122223333', '01/23', '123', 1);
INSERT INTO credit_card VALUES (1, '0000111122224444', '01/22', '123', 0);
INSERT INTO card_type VALUES (0, 'VISA standart', 'VISA');
INSERT INTO card_type VALUES (1, 'VISA gold', 'VISA');
INSERT INTO card_type VALUES (2, 'MasterCard standart', 'MasterCard');
INSERT INTO operation VALUES (0, 'op_type_list', 123.00, '1.1.2022', 0);

COMMIT;
