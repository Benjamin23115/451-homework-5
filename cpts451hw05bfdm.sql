-- Washington State University: CptS451
-- Semester: Spring 2024
-- Student: Benjamin Farias Dela Mora
-- Assignment: Homework 05
-- Operating System: MS Windows

-- Q1
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

use CptS451_SecretProject_RDS;

select fn_PhoneFormat_bfdm ('1982736450');
select fn_PhoneFormat_bfdm ('198.273.6450');
select fn_PhoneFormat_bfdm ('198-273-6450');
select fn_PhoneFormat_bfdm ('(509) 335-3564');
select fn_PhoneFormat_bfdm ('123-4567');
select fn_PhoneFormat_bfdm ('1234567890123');
select fn_PhoneFormat_bfdm ('Washington');
SELECT FN_PHONEFORMAT_BFDM('NULL');

-- Q2 

DELIMITER //
create procedure sp_InsertSubjectX_bfdm (in fullName varchar(255), in fullAddress varchar(255), out SubFname boolean, out SubLname boolean, out SubAddress boolean, out SubCity boolean, out SubState boolean, out subZip boolean)
BEGIN
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
set  firstName = SUBSTRING(fullName, 1, whitespace - 1);
set lastName = SUBSTRING(fullName, whitespace + 1);
-- validate if the individual parts are populated and are not null
if LENGTH(firstName) > 0 and firstName != null then
set SubFname = true;
else set SubFname = false;
end if;
if LENGTH(lastName) > 0 and lastName != null then
set SubLname = true;
else set SubLname = false;
end if;

--  turn the fullAddress into individual parts
set address = substring_index2(fullAddress, ':', 1);
set city = substring_index2(substring_index2(fullAddress, ':', 2), ':', -1);
set state = substring_index2(substring_index2(fullAddress, ':', 3), ':', -1);
set zip = substring_index2(substring_index2(fullAddress, ':', 4), ':', -1);

-- validate if the individual parts are populated and are not null

if LENGTH(address) > 0 and address != null then
set SubAddress = true;
else set SubAddress = false;
end if;

if LENGTH(city) > 0 and city != null then
set SubCity = true;
else set SubCity = false;
end if;


if LENGTH(state) = 2 and state != null then
set SubState = true;
else set SubState = false;
end if;


if LENGTH(zip) = 5 and zip != null then
set SubZip = true;
else set SubZip = false;
end if;


end if;
END//
DELIMITER ;

-- Q3
use wsutc_cpts451_university;
alter table offering
add offLimit int,
add offNumEnroll int;

delimiter //

create procedure sp_OffNumCalc_bfdm (out offRecordUpdated int)
begin
    declare done boolean default false;
    declare offeringID int;
    declare currentEnrollment int;
    declare newEnrollment int;
    declare updatedCount int default 0;
    declare offLimit int default 10;

    declare offering_cursor cursor for
    select OfferingID, CurrentEnrollment
    from offering;

    declare continue handler for not found set done = true;

    open offering_cursor;

    calc_loop: loop
        -- Fetch offering details
        fetch offering_cursor into offeringID, currentEnrollment;

        if done then
            leave calc_loop;
        end if;

        set newEnrollment = (select COUNT(*) from enrollment where OfferingID = offeringID);

        if newEnrollment <> currentEnrollment then
            if newEnrollment <= offLimit then
                update offering
                set OffNumEnroll = newEnrollment
                where OfferingID = offeringID;
                
                set updatedCount = updatedCount + 1;
            end if;
        end if;
    end loop calc_loop;

    close offering_cursor;
    set offRecordUpdated = updatedCount;
end //

-- Q3 tests

INSERT INTO offering (OfferNo, CourseNo, OffTerm, OffYear, OffLocation, OffTime, FacNo, OffDays, OffLimit, OffNumEnrolled)
VALUES (1, 'CPT451', 'Spring', 2024, 'Room A', '10:00', 'FAC101', 'MWF', 20, 0);

CALL sp_OffNumCalc_bfdm(@updatedCount1);

SELECT * FROM offering;

INSERT INTO offering (OfferNo, CourseNo, OffTerm, OffYear, OffLocation, OffTime, FacNo, OffDays, OffLimit, OffNumEnrolled)
VALUES (2, 'CPT452', 'Fall', 2024, 'Room B', '09:00', 'FAC102', 'TTH', 15, 8);

CALL sp_OffNumCalc_bfdm(@updatedCount2);

SELECT * FROM offering;

INSERT INTO offering (OfferNo, CourseNo, OffTerm, OffYear, OffLocation, OffTime, FacNo, OffDays, OffLimit, OffNumEnrolled)
VALUES 
(3, 'CPT453', 'Spring', 2024, 'Room C', '11:00', 'FAC103', 'MWF', 25, 18),
(4, 'CPT454', 'Summer', 2024, 'Room D', '14:00', 'FAC104', 'TTH', 30, 24);

CALL sp_OffNumCalc_bfdm(@updatedCount3);

SELECT * FROM offering;

INSERT INTO offering (OfferNo, CourseNo, OffTerm, OffYear, OffLocation, OffTime, FacNo, OffDays, OffLimit, OffNumEnrolled)
VALUES 
(5, 'CPT455', 'Fall', 2024, 'Room E', '13:00', 'FAC105', 'MWF', 20, 15),
(6, 'CPT456', 'Spring', 2024, 'Room F', '10:00', 'FAC106', 'TTH', 25, 20);

CALL sp_OffNumCalc_bfdm(@updatedCount4);

SELECT * FROM offering;

delimiter //

-- Q4 

USE CptS451_SecretProject_RDS;

DELIMITER //

create trigger tr_ib_Task_bfdm before insert on Task
for each row
begin
    declare errorMessage varchar(255);

    if NEW.TaskCost < 0 then
        set errorMessage = 'Error: Negative data insertion not allowed.';
        signal sqlstate '45000' set message_text = errorMessage;
    end if;
end;
//

create trigger tr_ub_Task_bfdm before update on Task
for each row
begin
    declare errorMessage varchar(255);

    if NEW.TaskCost < 0 then
        set errorMessage = 'Error: Negative data update not allowed.';
        signal sqlstate '45000' set message_text = errorMessage;
    end if;
end;
//

DELIMITER ;

-- Q4 test cases

UPDATE Task SET TaskCost = 123.45 WHERE TaskNo = 7;
UPDATE Task SET TaskCost = -43.21 WHERE TaskNo = 7;
INSERT Task(TaskDesc, TaskType, TaskCost) VALUES('Myringotomy', 5, 33.33);
INSERT Task(TaskDesc, TaskType, TaskCost) VALUES('Curettage', 3, -22.22);


-- Q5

use WSUTC_CptS451_OrderEntry11;

delimiter //

CREATE TRIGGER tr_ia_Task_bfdm
AFTER INSERT ON Order
FOR EACH ROW
BEGIN
    UPDATE Customer
    SET CustBal = CustBal + NEW.TotalAmt
    WHERE CustID = NEW.CustID;
END;

CREATE TRIGGER tr_ua_Task_bfdm
AFTER UPDATE ON Order
FOR EACH ROW
BEGIN
    DECLARE old_total DECIMAL(10,2);
    DECLARE new_total DECIMAL(10,2);

    SELECT TotalAmt INTO old_total FROM Order WHERE OrderID = OLD.OrderID;
    SELECT TotalAmt INTO new_total FROM Order WHERE OrderID = NEW.OrderID;

    UPDATE Customer
    SET CustBal = CustBal - old_total + new_total
    WHERE CustID = NEW.CustID;
END;

CREATE TRIGGER tr_da_Task_bfdm
AFTER DELETE ON Order
FOR EACH ROW
BEGIN
    UPDATE Customer
    SET CustBal = CustBal - OLD.TotalAmt
    WHERE CustID = OLD.CustID;
END;

-- Q5 test cases

-- Testing INSERT trigger
INSERT INTO Order (OrderID, CustID, TotalAmt) VALUES (1, 101, 50.00);

-- Testing UPDATE trigger
UPDATE Order SET TotalAmt = 60.00 WHERE OrderID = 1;

-- Testing DELETE trigger
DELETE FROM Order WHERE OrderID = 1;

delimiter ;
