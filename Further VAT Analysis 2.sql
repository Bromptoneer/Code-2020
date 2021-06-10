-----------------------------------------------------------------------------------------------------------------------------------
-- SET UP THE QUERY
-----------------------------------------------------------------------------------------------------------------------------------
USE TEMPDB
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#debts') AND TYPE = 'U') DROP TABLE #debts
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#vat3') AND TYPE = 'U') DROP TABLE #vat3
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#results') AND TYPE = 'U') DROP TABLE #results

USE MIS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

-----------------------------------------------------------------------------------------------------------------------------------
-- CREATE A TEMPORARY TABLE TO HOLD THE EXTRACTED DATA
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #debts
(
CD_BUSE      CHAR(3),
EXTERNAL_SA_ID CHAR (9),
true_bal_amt DECIMAL(11,2)
)

INSERT INTO #debts

select
CD_BUSE ,
EXTERNAL_SA_ID ,
true_bal_amt

FROM
MISUserData.[UK\PB32946].VCRO_SERV_ACCT_01112020 
WHERE --cd_atro in ('SE','SSE','SWAE','SEG')
 CD_BUSE IN ('ESU','GSS')

-----------------------------------------------------------------------------------------------------------------------------------
-- INDEX THE TABLE
-----------------------------------------------------------------------------------------------------------------------------------
CREATE CLUSTERED INDEX DEBTS ON #DEBTS
(CD_BUSE ,
EXTERNAL_SA_ID ,
true_bal_amt)
WITH
(SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)




-----------------------------------------------------------------------------------------------------------------------------------
-- CREATE A TEMPORARY TABLE TO HOLD THE EXTRACTED DATA
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #VAT3
(
CD_BUSE      CHAR(3),
EXTERNAL_SA_ID CHAR (9),
NET_AMOUNT DECIMAL(11,2),
VAT_AMOUNT DECIMAL(11,2),
GROSS_AMOUNT DECIMAL(11,2)
)

INSERT INTO #VAT3

select

b.cd_buse,
B.EXTERNAL_SA_ID,
sum(net_amount) as Net_amount,
sum(vat_amount) as Vat_amout,

(sum(net_amount) + sum(vat_amount)) as Gross_amount

from

vmi_vat3_detail_current as b

where b.cd_buse in ('esu','gss')
and b.cd_atro in ('SE','SSE','SWAE','seg')
group by
b.cd_buse,
B.EXTERNAL_SA_ID


-----------------------------------------------------------------------------------------------------------------------------------
-- INDEX THE TABLE
-----------------------------------------------------------------------------------------------------------------------------------
CREATE CLUSTERED INDEX VAT3 ON #VAT3
(CD_BUSE,EXTERNAL_SA_ID, NET_AMOUNT ,VAT_AMOUNT ,GROSS_AMOUNT)
WITH
(SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
-----------------------------------------------------------------------------------------------------------------------------------
-- SELECT THE DATA OUT OF THE NEW TABLE
-----------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------
-- CREATE A TEMPORARY TABLE TO HOLD THE EXTRACTED DATA
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #results
(
CD_BUSE      CHAR(3),
EXTERNAL_SA_ID CHAR (9),
NET_AMOUNT DECIMAL(11,2),
VAT_AMOUNT DECIMAL(11,2),
GROSS_AMOUNT DECIMAL(11,2),
true_bal_amt DECIMAL(11,2),
vat_on_debts DECIMAL(11,2)
)

INSERT INTO #results



Select
b.cd_buse,
B.EXTERNAL_SA_ID,
(b.Net_amount) as VAT3_net,
(b.Vat_amount) as VAT3vat,
(b.Gross_amount) as VAT3_gross,
(a.true_bal_amt) as Debts,
(cast (a.true_bal_amt *5/105 as decimal(11,2))) as Vat_on_debt


from
--#debts
#VAT3 			
as b				
LEFT OUTER JOIN				
--#vat3
#DEBTS		
as a				
ON 	a.external_sa_id=b.external_sa_id	



-----------------------------------------------------------------------------------------------------------------------------------
-- INDEX THE TABLE
-----------------------------------------------------------------------------------------------------------------------------------
CREATE CLUSTERED INDEX RESULTS ON #results
(CD_BUSE,EXTERNAL_SA_ID, NET_AMOUNT ,VAT_AMOUNT ,GROSS_AMOUNT, true_bal_amt, vat_on_debts)
WITH
(SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
-----------------------------------------------------------------------------------------------------------------------------------
-- SELECT THE DATA OUT OF THE NEW TABLE
-----------------------------------------------------------------------------------------------------------------------------------

select 
res.EXTERNAL_SA_ID,
sa.ID,
sum(res.NET_AMOUNT) as VAT3_net ,
sum(res.VAT_AMOUNT) as VAT3_vat,
sum(res.GROSS_AMOUNT) as VAT3_gross,
sum(res.true_bal_amt) as debts_0111

into misuserdata.[uk\pb32946].vat3_imbalances

from
#results				res
inner join
VCRO_SERV_ACCT			sa
on res.EXTERNAL_SA_ID = sa.EXTERNAL_SA_ID

where res.true_bal_amt is NuLL

group by
res.EXTERNAL_SA_ID,
sa.ID


order by EXTERNAL_SA_ID





use MISUserData grant select on misuserdata.[uk\pb32946].vat3_imbalances to [uk\tr10952]



--DROP TABLE #VAT3
--DROP TABLE #debts
--DROP TABLE #results
