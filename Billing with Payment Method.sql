SELECT
SALES.FIN_YEAR
,SALES.MONTH
,SALES.BUS_USE
,SALES.ACCOUNT_CODE
,SALES.COST_CENTRE
,SALES.JOB_NUMBER
,CASE
	WHEN SP.ID_SPTY IN ('GSP','EDK') THEN 'PREPAYMENT'
	WHEN CA.CD_PMET LIKE 'DD%' THEN 'DD'
	ELSE 'ON DEMAND' END															PAYMENT_METHOD
,SUM(SALES.UNITS)																	USAGE
,SUM(REVENUE)																		REVENUE

FROM
VMI_SALES_REPORT_DETAIL																SALES
INNER JOIN
VRT_VCRO_SERV_ACCT																	SA
ON SALES.ID_SA = SA.ID
INNER JOIN
VCRO_SERVICE_PLAN																	SP
ON SA.ID_SP = SP.ID
INNER JOIN
VCRO_CA_SERV_ACCT																	CASA
ON SA.ID = CASA.ID_SA
INNER JOIN
VMI_CUST_ACCOUNT																	CA
ON CASA.ID_CRAC = CA.ID_CRAC

WHERE
FIN_YEAR = '2020'
AND BUS_USE IN ('ESU','GSS')
AND SALES.ACCOUNT_CODE LIKE '3%'

GROUP BY
SALES.FIN_YEAR
,SALES.MONTH
,SALES.BUS_USE
,SALES.ACCOUNT_CODE
,SALES.COST_CENTRE
,SALES.JOB_NUMBER
,CASE
	WHEN SP.ID_SPTY IN ('GSP','EDK') THEN 'PREPAYMENT'
	WHEN CA.CD_PMET LIKE 'DD%' THEN 'DD'
	ELSE 'ON DEMAND' END								