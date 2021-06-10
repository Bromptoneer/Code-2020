SELECT
RECV.CD_PMET
,RECV.CODE_PMED
,RECV.CODE_PPTY
,SUM(RECV.AMT)

FROM
MISUserData.[UK\PB32946].VMI_AGED_RECV_01072020	RECV
INNER JOIN
MISUserData.[UK\PB32946].VCRO_SERV_ACCT_01072020	SA
ON RECV.ID_SA = SA.ID
INNER JOIN
VCRO_SERVICE_PLAN	SP
ON SA.ID_SP = SP.ID

WHERE
RECV.AMT > '0'
AND RECV.CD_BUSE IN ('ESU','GSS')
AND RECV.CD_ATRO NOT IN ('BE','BEG','SYSB')
AND RECV.AGE_MO > 'M2'
AND RECV.FIN_LIVE = 'L'
--AND RECV.CD_COCT IS NOT NULL
AND (RECV.FLWUP_DT < '2020-07-01' OR RECV.FLWUP_DT IS NULL)

GROUP BY
RECV.CD_PMET
,RECV.CODE_PMED
,RECV.CODE_PPTY




SELECT TOP 100 * FROM VMI_AGED_RECV