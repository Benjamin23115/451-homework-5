-- Washington State University: CptS451
-- Semester: Spring 2024
-- Student: Benjamin Farias Dela Mora
-- Assignment: Homework 05
-- Operating System: MS Windows

-- Q1

use CptS451_SecretProject_RDS;

DELIMITER //
create function fn_PhoneFormat_bfdm (phoneNumber varchar(255))
returns varchar(10)
deterministic
BEGIN
declare regexPattern varchar(255);
set regexPattern = '^[0-9]{10}$';
if phoneNumber is null then
return null;
elseif LENGTH(phoneNumber) != 10 then
return null;
elseif phoneNumber REGEXP regexPattern then
return phoneNumber;
else return null;
end if;
END//
delimiter ;

-- Q1 test cases

select fn_PhoneFormat_bfdm ('1982736450');
select fn_PhoneFormat_bfdm ('198.273.6450');
select fn_PhoneFormat_bfdm ('198-273-6450');
select fn_PhoneFormat_bfdm ('(509) 335-3564');
select fn_PhoneFormat_bfdm ('123-4567');
select fn_PhoneFormat_bfdm ('1234567890123');
select fn_PhoneFormat_bfdm ('Washington');
select fn_PhoneFormat_bfdm('NULL');

-- Q2
use CptS451_SecretProject_RDS;
DELIMITER //
create procedure sp_InsertSubjectX_bfdm (
    in fullName varchar(255),
    in fullAddress varchar(255),
    out SubFname boolean,
    out SubLname boolean,
    out SubAddress boolean,
    out SubCity boolean,
    out SubState boolean,
    out SubZip boolean
)
begin
    declare whitespace int;
    declare firstName varchar(255);
    declare lastName varchar(255);
    declare address varchar(255);
    declare city varchar(255);
    declare state varchar(2);
    declare zip varchar(5);

    set whitespace = LOCATE(' ', fullName);
    if whitespace > 0 then
        -- Separate the complete string into substrings
        set firstName = SUBSTRING(fullName, 1, whitespace - 1);
        set lastName = SUBSTRING(fullName, whitespace + 1);

        -- validate if the individual parts are populated and are not null
        set SubFname = (LENGTH(firstName) > 0 and firstName is not null);
        set SubLname = (LENGTH(lastName) > 0 and lastName is not null);
    end if;

    -- Extract address parts
    set address = SUBSTRING_INDEX(fullAddress, ':', 1);
    set city = SUBSTRING_INDEX(SUBSTRING_INDEX(fullAddress, ':', 2), ':', -1);
    set state = SUBSTRING_INDEX(SUBSTRING_INDEX(fullAddress, ':', 3), ':', -1);
    set zip = SUBSTRING_INDEX(SUBSTRING_INDEX(fullAddress, ':', 4), ':', -1);

    -- Validate address parts
    set SubAddress = (LENGTH(address) > 0 and address is not null);
    set SubCity = (LENGTH(city) > 0 and city is not null);
    set SubState = (LENGTH(state) = 2 and state is not null);
    set SubZip = (LENGTH(zip) = 5 and zip is not null);
end//
DELIMITER ;

-- Q2 extension
DELIMITER //

create function fn_InsertSubjectX_bfdm (
    fullName varchar(255),
    fullAddress varchar(255)
)
returns int
deterministic
begin
    declare SubFname boolean;
    declare SubLname boolean;
    declare SubAddress boolean;
    declare SubCity boolean;
    declare SubState boolean;
    declare SubZip boolean;

    call sp_InsertSubjectX_bfdm(
        fullName,
        fullAddress,
        SubFname,
        SubLname,
        SubAddress,
        SubCity,
        SubState,
        SubZip
    );

    if not SubFname then
        return 1;
    elseif not SubLname then
        return 2;
    elseif not SubAddress then
        return 3;
    elseif not SubCity then
        return 4;
    elseif not SubState then
        return 5;
    elseif not SubZip then
        return 6;
   else
        return 0;
    END IF;
END//

DELIMITER ;



-- Q2 test cases

SELECT 
    FN_INSERTSUBJECTX_BFDM('Christy ',
            '7340 South Jackson Hill:Peoria:IL:61602') AS ErrorCode;
select fn_InsertSubjectX_bfdm("Geraldine Mason", "7652 Southwest Meadow Heights:Syracuse:NY:13202") AS ErrorCode;
select fn_InsertSubjectX_bfdm("Jennifer Thomas", NULL) AS ErrorCode;
select fn_InsertSubjectX_bfdm(NULL, "4149 Meadow Canyon:Westminster:CO:80030") AS ErrorCode;
select fn_InsertSubjectX_bfdm("Patrick Russell", "2233 View Lane:Fishers::46037") AS ErrorCode;
select fn_InsertSubjectX_bfdm("Rose Adams", "1849 Southeast 3rd Bypass:Jefferson City:MO:65101") AS ErrorCode;


-- Q3
use WSUTC_CptS451_University;

alter table offering
add column offLimit int default 10,
add column offNumEnrolled int;

DELIMITER //

create procedure sp_OffNumCalc_bfdm (out updatedCount int)
begin
    declare done boolean default false;
    declare offeringID int;
    declare currentEnrollment int;
    declare newEnrollment int;
    declare enrollCount int default 0;

    declare offering_cursor cursor for
        select OfferingID, CurrentEnrollment
        from offering;

    declare continue handler for not found set done = true;

    open offering_cursor;

    calc_loop: loop
        fetch offering_cursor into offeringID, currentEnrollment;

        if done then
            leave calc_loop;
        end if;

        set newEnrollment = (select COUNT(*) from enrollment where enrollment.OfferNo = offering.offerNo);

        if newEnrollment <> currentEnrollment then
            if newEnrollment <= (select offLimit from offering where OfferingID = offeringID) then
                update offering
                set offNumEnrolled = newEnrollment
                where OfferingID = offeringID;
                
                set enrollCount = enrollCount + 1;
            end if;
        end if;
    end loop calc_loop;

    close offering_cursor;
    set updatedCount = enrollCount;
end //

DELIMITER ;

create view vw_offNumBad_bfdm as
select *
from offering
where offNumEnrolled > offLimit;

-- Q3 tests

use WSUTC_CptS451_University;

insert into offering (OfferNo, CourseNo, OffTerm, OffYear, OffLocation, OffTime, FacNo, OffDays, OffNumEnrolled)
values (1112, 'IS320', 'SUMMER', 2020, 'BLM302', '10:30:00', NULL, 'MW', 0),
       (7778, 'FIN480', 'SPRING', 2020, 'BLM305', '13:30:00', '765-43-2109', 'MW', 5),
       (8889, 'IS320', 'SUMMER', 2020, 'BLM405', '13:30:00', '654-32-1098', 'MW', 20),
       (9877, 'IS460', 'SPRING', 2020, 'BLM307', '13:30:00', '654-32-1098', 'TTH', 50);

call sp_OffNumCalc_bfdm(@updatedCount1);

select *  from vw_offNumBad_bfdm;

delimiter //

-- Q4 

USE CptS451_SecretProjoffLimitect_RDS;

DELIMITER //

create trigger tr_ib_Task_bfdm before insert on Task
for each row
begin

    if NEW.TaskCost < 0 then
        call myFail('Negative data insertion not allowed.');
    end if;
end;

create trigger tr_ub_Task_bfdm before update on Task
for each row
begin

    if NEW.TaskCost < 0 then
        call myFail('Negative data update not allowed.');
    end if;
end;

DELIMITER ;

-- Q4 test cases

update Task set TaskCost = 123.45 where TaskNo = 7;
update Task set TaskCost = -43.21 where TaskNo = 7;
insert Task(TaskDesc, TaskType, TaskCost) values('Myringotomy', 5, 33.33);
insert Task(TaskDesc, TaskType, TaskCost) values('Curettage', 3, -22.22);


-- Q5

USE WSUTC_CptS451_OrderEntry11;

delimiter //
CREATE PROCEDURE handleNoRowsAffected()
BEGIN
    CALL myFail('Error: Customer does not exist');
END//
delimiter ;

DELIMITER //

CREATE TRIGGER tr_ia_task_bfdm AFTER INSERT ON OrdLine
FOR EACH ROW
BEGIN
    DECLARE prod_price DECIMAL(10, 2);

    SELECT ProdPrice INTO prod_price FROM product WHERE ProdNo = NEW.ProdNo;

    UPDATE customer
    JOIN ordertbl ON customer.CustNo = ordertbl.CustNo 
    SET customer.CustBal = customer.CustBal + (NEW.Qty * prod_price)
    WHERE ordertbl.OrdNo = NEW.OrdNo;

    IF ROW_COUNT() = 0 THEN
        CALL handleNoRowsAffected();
    END IF;
END //

CREATE TRIGGER tr_ua_task_bfdm AFTER UPDATE ON OrdLine
FOR EACH ROW
BEGIN
    DECLARE prod_price DECIMAL(10, 2);

    SELECT ProdPrice INTO prod_price FROM Product WHERE ProdNo = NEW.ProdNo;

    UPDATE customer
    JOIN ordertbl ON customer.CustNo = ordertbl.CustNo
    JOIN ordline ON ordertbl.OrdNo = ordline.OrdNo 
    SET customer.CustBal = customer.CustBal + ((NEW.Qty - OLD.Qty) * prod_price)
    WHERE ordline.OrdNo = NEW.OrdNo;

    IF ROW_COUNT() = 0 THEN
        CALL handleNoRowsAffected();
    END IF;
END //

CREATE TRIGGER tr_da_task_bfdm AFTER DELETE ON OrdLine
FOR EACH ROW
BEGIN
    DECLARE prod_price DECIMAL(10, 2);

SELECT 
    ProdPrice
INTO prod_price FROM
    product
WHERE
    ProdNo = OLD.ProdNo;

UPDATE customer
        JOIN
    ordertbl ON customer.CustNo = ordertbl.CustNo
        JOIN
    ordline ON ordertbl.OrdNo = ordline.OrdNo 
SET 
    CustBal = CustBal - (OLD.Qty * prod_price)
WHERE
    ordertbl.OrdNo = OLD.OrdNo;

    IF ROW_COUNT() = 0 THEN
        CALL handleNoRowsAffected();
    END IF;
END //

DELIMITER ;


-- Q5 test cases
delimiter //
-- Testing INSERT trigger
INSERT INTO OrdLine (OrdNo, ProdNo, Qty) VALUES ('O9919699', 'P4200344', 1);

-- Testing UPDATE trigger
UPDATE OrdLine SET Qty = 3 WHERE OrdNo = 'O9919698' AND ProdNo = 'P4200344';

-- Testing DELETE trigger
DELETE FROM OrdLine WHERE OrdNo = 'O9919698' AND ProdNo = 'P4200344';


delimiter ;


