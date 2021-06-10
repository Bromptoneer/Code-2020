SELECT
SALES.FIN_YEAR														FINANCIAL_YEAR
,SALES.MONTH														FINANCIAL_PERIOD
,SALES.JOB_NUMBER													BSV
,SALES.COST_CENTRE
,SALES.ACCOUNT_CODE
,SALES.EXTERNAL_SA_ID
,SP.DESCR															SERVICE_PLAN_DESCRIPTION
,'BILLS'															TRANSACTION_TYPE
,FAIT.DESCR															FAIT_DESCRIPTION
,SPC.DESCR															COMPONENT_DESCRIPTION
,CMG.DESCR															COMPONENT_GROUP_DESCRIPTION
,CMT.DESCR															COMPONENT_TYPE_DESCRIPTION
,SUM(SALES.UNITS)													SUM_USAGE
,SUM(SALES.REVENUE)													SUM_REVENUE

FROM
VMI_SALES_REPORT_DETAIL												SALES
INNER JOIN
VCRO_SERV_PLN_COMP													SPC
ON SALES.COMPONENT_ID = SPC.DBID
INNER JOIN
VCRO_COMPONENT_GRP													CMG
ON SALES.COMPONENT_GROUP_ID = CMG.ID
INNER JOIN
VCRO_COMPONENT_TYP													CMT
ON SALES.COMPONENT_TYPE_ID = CMT.ID AND SPC.ID_CMTP = CMT.ID
INNER JOIN
VCRO_FA_ITEM_TYPE													FAIT
ON SALES.FAIT = FAIT.CD
INNER JOIN
VCRO_SERVICE_PLAN													SP
ON SALES.SERVICE_PLAN = SP.ID

WHERE
SALES.FIN_YEAR = '2020'
AND SALES.SERVICE_PLAN LIKE 'CHP%'

GROUP BY
SALES.FIN_YEAR
,SALES.MONTH
,SALES.TRANS_DATE
,SALES.REV_CLASS
,SALES.JOB_NUMBER		
,SALES.COST_CENTRE
,SALES.ACCOUNT_CODE
,SALES.EXTERNAL_SA_ID
,SP.DESCR
,FAIT.DESCR				
,SPC.DESCR				
,CMG.DESCR				
,CMT.DESCR		

UNION ALL

SELECT
MCC.YR_NUM_ACPE_01													
,MCC.PERD_NUM_ACPE_01												
,MCC.JOB_NUMBER														
,MCC.COST_CENTRE
,MCC.ACCOUNT_CODE
,MCC.EXTERNAL_SA_ID
,SP.DESCR
,'MCCS'
,FAIT.DESCR
,''
,''
,''
,SUM(MCC.TTL_USG)													
,SUM(MCC.AMT)														

FROM
VMI_SALES_MCC														MCC
INNER JOIN
VCRO_SERVICE_PLAN													SP
ON MCC.ID_SP = SP.ID
INNER JOIN
VCRO_FA_ITEM_TYPE													FAIT
ON MCC.CD_FAIT = FAIT.CD			

WHERE
MCC.YR_NUM_ACPE_01 = '2020'
AND SP.ID LIKE '%CHP%'

GROUP BY
MCC.YR_NUM_ACPE_01													
,MCC.PERD_NUM_ACPE_01												
,MCC.JOB_NUMBER														
,MCC.COST_CENTRE
,MCC.ACCOUNT_CODE
,MCC.EXTERNAL_SA_ID
,SP.DESCR
,FAIT.DESCR	