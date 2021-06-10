SELECT
BUSE.DESCR
--,SUM(SA.TRUE_BAL_AMT)
,SUM(RECV.AMT)

FROM
MISUserData.[UK\PB32946].VMI_AGED_RECV_01072020			RECV
--INNER JOIN
--MISUserData.[UK\PB32946].VCRO_SERV_ACCT_01072020	SA
--ON RECV.ID_SA = SA.ID
INNER JOIN
VCRO_BUSNS_USE										BUSE
ON RECV.CD_BUSE = BUSE.CD
INNER JOIN
VCRO_CA_SERV_ACCT			CASA
ON RECV.ID_SA = CASA.ID_SA
INNER JOIN
VCRO_CUST_ACCOUNT			CA
ON CASA.ID_CRAC = CA.ID
INNER JOIN
VCRO_BRAND					BRD
ON CA.CD_BRND = BRD.CD
INNER JOIN
VCRO_BRAND_DESCR	BRDE
ON BRD.CD_BRDE = BRDE.CD
--INNER JOIN
--VCRO_SERVICE_PLAN			SP
--ON RECV.ID_SP = SP.ID
INNER JOIN
VCRO_AUTH_TR_ORG			ATRO
ON BRD.CD_ATRO = ATRO.CD

WHERE
ATRO.CD NOT IN ('BE','BEG','SYSB')
AND BUSE.CD IN ('ESU','GSS','TSS','DAL','MOP','GSU')

GROUP BY
BUSE.DESCR