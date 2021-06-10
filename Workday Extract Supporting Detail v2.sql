--*************************************************************************************************************************************************************************
-- RUN THIS QUERY ON WORKING DAY 2 FOR THE PERIOD BEING CLOSED
-- CS YEAR AND PERIOD ARE USED, EG. APRIL 2020 = YEAR 2021 AND PERIOD 1
-- MISUSERDATA TABLE CS_WORKDAY_GL_CONVERSION IS POPULATED FROM A SPREADSHEET AND MAY NEED TO BE UPDATED PERIODICALLY MAKING SURE TO MAINTAIN EXISTING TABLE STRUCTURE
--***************************************************************************************************************************************************************************

-- SET THE YEAR AND PERIOD BEING CLOSED BELOW

DECLARE @YEAR																										CHAR(4)
DECLARE @PERIOD																										CHAR(2)
SET @YEAR = '2021'
SET @PERIOD = '07'

-- DROP THE TEMP TABLE IF IT ALREADY EXISTS
USE tempdb
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#FT') AND TYPE = 'U') DROP TABLE #FT

USE MIS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

CREATE TABLE #FT (
ID_FE_01																											BIGINT
,ID_SA_FE_01																										BIGINT
,DBID_FC_01																											SMALLINT
,CR_GL_CODE																											VARCHAR(33)
,DBID_FC_02																											SMALLINT
,DR_GL_CODE																											VARCHAR(33)
,AMT																												DECIMAL(11,2)
)

CREATE INDEX FT ON #FT (
ID_FE_01	
,ID_SA_FE_01
,DBID_FC_01	
,DBID_FC_02
)

INSERT INTO #FT (
ID_FE_01	
,ID_SA_FE_01
,DBID_FC_01	
,DBID_FC_02
,AMT
)

SELECT
ID_FE_01	
,ID_SA_FE_01
,DBID_FC_01	
,DBID_FC_02
,AMT

FROM
VCRO_FIN_TRANS

WHERE
YR_NUM_ACPE_01 = @YEAR
AND PERD_NUM_ACPE_01 = @PERIOD

UPDATE #FT
SET #FT.CR_GL_CODE = TEMP.GL_CODE
FROM	(
		SELECT
		DBID
		,GL_CODE
		FROM
		VCRO_FIN_CODE
		) TEMP
WHERE
#FT.DBID_FC_01 = TEMP.DBID

UPDATE #FT
SET #FT.DR_GL_CODE = TEMP.GL_CODE
FROM	(
		SELECT
		DBID
		,GL_CODE
		FROM
		VCRO_FIN_CODE
		) TEMP
WHERE
#FT.DBID_FC_02 = TEMP.DBID

DELETE FROM #FT
WHERE
#FT.CR_GL_CODE NOT LIKE '% 90%1'

SELECT
FT.DR_GL_CODE
,SUM(FT.AMT)							AMOUNT

FROM 
#FT										FT
INNER JOIN
VCRO_SERV_ACCT							SA
ON FT.ID_SA_FE_01 = SA.ID

GROUP BY
FT.DR_GL_CODE

SELECT
FT.CR_GL_CODE							AMOUNT
,SUM(FT.AMT)

FROM 
#FT										FT
INNER JOIN
VCRO_SERV_ACCT							SA
ON FT.ID_SA_FE_01 = SA.ID

GROUP BY
FT.CR_GL_CODE


