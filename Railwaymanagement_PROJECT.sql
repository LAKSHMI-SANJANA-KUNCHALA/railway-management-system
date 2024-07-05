CREATE DATABASE R;
USE R;
CREATE TABLE TRAIN(T_NO INT PRIMARY KEY , START_S VARCHAR(20) , END_S VARCHAR(20));
CREATE TABLE STATION(T_NO INT ,FOREIGN KEY(T_NO) REFERENCES TRAIN(T_NO),STOP VARCHAR(20) ,STOP_TIME TIME);
CREATE TABLE TICKET_TRAIN(TR_NO INT , DEPARTURE_DATE VARCHAR(20) , PRIMARY KEY(TR_NO,DEPARTURE_DATE),foreign key(TR_NO) REFERENCES TRAIN(T_NO),
AC_LOWER INT, AC_UPPER INT,S_LOWER INT, S_UPPER INT);
CREATE TABLE USERS(U_ID INT,P_ID INT,AGE INT,LOWER_BEARTH_NEED INT,SEAT_TYPE VARCHAR(30) CONSTRAINT CHECK (SEAT_TYPE IN ('AC', 'SLEEPER')),PRIMARY KEY(P_ID));
CREATE TABLE PASSENGERS(P_ID INT ,TR_NO INT ,TICKET_ID INT,D_DATE VARCHAR(20),FOREIGN KEY(TR_NO,D_DATE) REFERENCES TICKET_TRAIN(TR_NO,DEPARTURE_DATE),FOREIGN KEY(P_ID) REFERENCES USERS(P_ID));
CREATE TABLE WAITING_LIST(P_ID INT,TR_NO INT,D_DATE VARCHAR(20),BOOKING_STATUS INT,FOREIGN KEY(P_ID) REFERENCES USERS(P_ID));
DROP TABLE PASSENGERS;
CREATE TABLE PASSENGERS(P_ID INT ,TR_NO INT ,TICKET_ID INT,D_DATE VARCHAR(20),TICKET_TYPE VARCHAR(20),FOREIGN KEY(TR_NO,D_DATE) REFERENCES TICKET_TRAIN(TR_NO,DEPARTURE_DATE),FOREIGN KEY(P_ID) REFERENCES USERS(P_ID));

ALTER TABLE  USERS ADD COLUMN T_NO INT ;
ALTER TABLE  USERS ADD COLUMN D_DATE VARCHAR(20) ;

ALTER TABLE PASSENGERS DROP COLUMN TICKET_ID;
ALTER TABLE PASSENGERS ADD COLUMN TICKET_ID INT(20) AUTO_INCREMENT PRIMARY KEY;

DROP PROCEDURE PASSENGER_INSERT;
delimiter $$
CREATE PROCEDURE PASSENGER_INSERT(IN P INT)
BEGIN
DECLARE SEAT VARCHAR(20);
DECLARE available_tickets INT;
DECLARE TNO INT;
DECLARE DA VARCHAR(20);
DECLARE ST VARCHAR(20);
SELECT SEAT_TYPE INTO SEAT  FROM USERS WHERE P_ID=P ;
SELECT D_DATE INTO DA  FROM USERS WHERE P_ID=P ;
SELECT T_NO INTO TNO  FROM USERS WHERE P_ID=P ;
    SET available_tickets = (
        SELECT 
            CASE 
                WHEN SEAT = 'AC' THEN AC_LOWER + AC_UPPER
                WHEN SEAT = 'SLEEPER' THEN S_LOWER  + S_UPPER
                ELSE 0
            END
        FROM TICKET_TRAIN
        WHERE TR_NO = TNO AND DEPARTURE_DATE = DA
    );
    IF available_tickets > 0 THEN
        INSERT INTO PASSENGERS (P_ID, TR_NO, D_DATE, TICKET_TYPE)
        VALUES (P, TNO, DA, 
                CASE 
                    WHEN (SELECT AGE FROM USERS WHERE P_ID = P) >= 60 && (SELECT AC_LOWER FROM TICKET_TRAIN WHERE TR_NO=TNO)>0 AND SEAT="AC" THEN 'ALOWER_BERTH'
                    WHEN (SELECT AGE FROM USERS WHERE P_ID = P) >= 60 && (SELECT S_LOWER FROM TICKET_TRAIN WHERE TR_NO=TNO)>0 AND SEAT="SLEEPER" THEN 'SLOWER_BERTH'
                    WHEN (SELECT LOWER_BEARTH_NEED FROM USERS WHERE P_ID = P) = 1&& (SELECT AC_LOWER FROM TICKET_TRAIN WHERE TR_NO=TNO)>0 AND SEAT="AC" THEN 'ALOWER_BERTH'
					WHEN (SELECT LOWER_BEARTH_NEED FROM USERS WHERE P_ID = P) = 1&& (SELECT S_LOWER FROM TICKET_TRAIN WHERE TR_NO=TNO)>0 AND SEAT="SLEEPER" THEN 'SLOWER_BERTH'

                    ELSE 'NORMAL'
                END);
   SELECT TICKET_TYPE INTO ST FROM PASSENGERS WHERE P_ID=P;             
  UPDATE TICKET_TRAIN
        SET 
            AC_LOWER = AC_LOWER - CASE WHEN SEAT = 'AC'AND ST='ALOWER_BERTH' THEN 1 ELSE 0 END,
            AC_UPPER = AC_UPPER - CASE WHEN SEAT = 'AC'AND ST='NORMAL' THEN 1 ELSE 0 END,
            S_LOWER = S_LOWER - CASE WHEN SEAT = 'SLEEPER' AND  ST='SLOWER_BERTH'THEN 1 ELSE 0 END,
            S_UPPER = S_UPPER - CASE WHEN SEAT = 'SLEEPER' AND ST='NORMAL' THEN 1 ELSE 0 END
        WHERE TR_NO = TNO AND DEPARTURE_DATE = DA;
    ELSE
        INSERT INTO WAITING_LIST (P_ID, TR_NO, D_DATE, BOOKING_STATUS)
        VALUES (P, TNO, DA, 0);
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE CANCELLATION;

DELIMITER $$
CREATE PROCEDURE CANCELLATION(IN T INT)
BEGIN
DECLARE TNO INT;
DECLARE DA VARCHAR(20);
DECLARE ST VARCHAR(20);
DECLARE P INT;
SELECT TR_NO ,D_DATE ,TICKET_TYPE INTO TNO,DA,ST FROM PASSENGERS WHERE TICKET_ID =T;
DELETE FROM PASSENGERS WHERE TICKET_ID=T;

SELECT P_ID INTO P FROM WAITING_LIST WHERE  BOOKING_STATUS=0 AND TR_NO =TNO AND D_DATE=DA LIMIT 1;

UPDATE WAITING_LIST
SET BOOKING_STATUS=1 WHERE P_ID=P;

INSERT INTO PASSENGERS(P_ID,TR_NO,D_DATE,TICKET_TYPE) VALUES(P,TNO,DA,ST);
END$$
DELIMITER ;


INSERT INTO TRAIN VALUES(123,"Nalgonda","Hyderabad"),(124,"Mangalore","Bengalore"),(125,"Bengalore","Mangalore"),(126,"Ongole","Guntur");
Insert INTO STATION VALUES(123,"Hyderabad",'23:00:00'),(124,"Mangalore",'00:15:00'),(123,"Nalgonda",'02:10:00'),(125,"Guntur",'15:30:00');
INSERT INTO TICKET_TRAIN VALUES(123,'2024-03-25',2,2,2,2),(124,'2024-03-25',0,2,1,2);
insert into USERS VALUES(1,14,18,1,"AC",124,'2024-03-25');
insert into USERS VALUES(1,2,18,1,"AC",124,'2024-03-25');
insert into USERS VALUES(1,3,18,1,"AC",124,'2024-03-25');
Insert into USERS VALUES(1,13,18,1,"AC",123,'2024-03-25');
Insert into USERS VALUES(1,15,60,0,"AC",123,'2024-03-25');
Insert into USERS VALUES(1,16,18,1,"AC",123,'2024-03-25');
Insert into USERS VALUES(1,19,18,1,"AC",123,'2024-03-25');
Insert into USERS VALUES(1,18,18,0,"AC",123,'2024-03-25');

SELECT * FROM WAITING_LIST;
SELECT * FROM PASSENGERS;
SELECT * FROM TICKET_TRAIN;
SELECT * FROM USERS;

 CALL PASSENGER_INSERT(14);
 CALL PASSENGER_INSERT(2);
 CALL PASSENGER_INSERT(3);
 CALL PASSENGER_INSERT(18);
 CALL PASSENGER_INSERT(15);
 
 CALL CANCELLATION(2);
 
 TRUNCATE TABLE WAITING_LIST;
 TRUNCATE TABLE PASSENGERS;
