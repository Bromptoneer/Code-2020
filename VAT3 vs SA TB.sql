SELECT top 1000
VAT3.EXTERNAL_SA_ID
,SUM(VAT3.NET_AMOUNT + VAT3.VAT_AMOUNT)				VAT3_BALANCE
,SA.TRUE_BAL_AMT

--INTO #VAT3BALS

FROM
VMI_VAT3_DETAIL_CURRENT								VAT3
INNER JOIN
VRT_VMI_SERV_ACCT									SA
ON VAT3.ID_SA = SA.ID_SA AND VAT3.SECTION = 'D1'

WHERE
SA.TRUE_BAL_AMT < '0'

GROUP BY
VAT3.EXTERNAL_SA_ID
,SA.TRUE_BAL_AMT

SELECT
SUM(VAT3_BALANCE)
,SUM(TRUE_BAL_AMT)

FROM
#VAT3BALS