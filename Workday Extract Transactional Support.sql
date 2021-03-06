DECLARE @YEAR																										CHAR(4)
DECLARE @PERIOD																										CHAR(2)
SET @YEAR = '2021'
SET @PERIOD = '06'

USE MIS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
FT.YR_NUM_ACPE_01
,FT.PERD_NUM_ACPE_01
,FC01.GL_CODE																										CR_GL_CODE
,FC02.GL_CODE																										DR_GL_CODE


FROM
VCRO_FIN_TRANS																										FT
INNER JOIN
VCRO_FIN_CODE																										FC01
ON 
FT.DBID_FC_01 = FC01.DBID
INNER JOIN
VCRO_FIN_CODE																										FC02
ON FT.DBID_FC_02 = FC02.DBID

WHERE
FT.YR_NUM_ACPE_01 = @YEAR
AND FT.PERD_NUM_ACPE_01 = @PERIOD
AND (FC01.GL_CODE LIKE '% 90%1' OR FC02.GL_CODE LIKE '% 90%1')