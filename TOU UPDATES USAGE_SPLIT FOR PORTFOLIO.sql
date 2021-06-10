---- ** Timing  01 hour 02 mins 21/08/2018 
---- ** Timing  01 hour 11 mins 18/09/2018 
---- ** Timing  01 hour 20 mins 01/10/2018 

SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @DATE                              AS VARCHAR(10)
DECLARE @DECDATE      AS DECIMAL(20,6)
DECLARE @DATE2                            AS VARCHAR(25)

SET @DATE                         =CONVERT(VARCHAR(10),GETDATE(),121)
SET @DATE2                       =CONVERT(VARCHAR(MAX),CURRENT_TIMESTAMP,21)
SET @DECDATE =REPLACE(REPLACE(REPLACE(@DATE2,'-',''),' ',''),':','')
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
USE TEMPDB

                IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#TEMP')                                               AND TYPE = 'U')                         DROP TABLE #TEMP
                IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#MTR_REGISTER')            AND TYPE = 'U')                                 DROP TABLE #MTR_REGISTER
                IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#FINAL_EACA')            AND TYPE = 'U') DROP TABLE #FINAL_EACA
                IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#MASTER_EAC')            AND TYPE = 'U') DROP TABLE #MASTER_EAC
               IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID('#DRVR')            AND TYPE = 'U') DROP TABLE #DRVR 

USE MIS
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

CREATE TABLE #DRVR  (CORE_MPAN_MPNT				BIGINT  NOT NULL
					,ID_ADDR					INT     NOT NULL
					,ID_SA						BIGINT  NULL)

CREATE TABLE #TEMP (ID_NTME                                                               [BIGINT]                               NOT       NULL
                                                                                ,NUM_MG                                                           [VARCHAR](2)                   NOT       NULL      )


CREATE TABLE #MTR_REGISTER(
                                                                                                [ID_NTME]                          [bigint]                                 NOT NULL,
                                                                                                [NUM]                                  [char](2)                                              NOT NULL,
                                                                                                [MULT_FCTR]                     [decimal](14, 6)                NOT NULL,
                                                                                                [CAN_CHK_IND]               [char](1)                                                              NULL,
                                                                                                [CONFIG_POSN]               [smallint]                                                            NULL,
                                                                                                [CD_MRDS]                         [char](1)                                                              NULL,
                                                                                                [CD_SMRS]                         [char](4)                                                              NULL,
                                                                                                [SEQ_NUM_SMTR]          [smallint]                                                            NULL,
                                                                                                [DBID_MGTY]                     [smallint]                                            NOT NULL,
                                                                                                [DBID_MGUT]                    [smallint]                                            NOT NULL,
                                                                                                [ID_ADDR]                          [int]                                                                       NULL,
                                                                                                [CD_TPRG]                          [VARCHAR](5)                                   NULL
                                                                                                                )
                                                                                                                
                                                                                                                
CREATE TABLE #FINAL_EACA

(CORE_MPAN_MPNT                     BIGINT    NOT NULL 
,CO_NUM                                            VARCHAR   (30)     NOT NULL
,ID_NTME            BIGINT    NOT NULL 
,NUM                 VARCHAR   (2)     NOT NULL
,MULT_FCTR                 DECIMAL   (14,6)   NOT NULL
,CAN_CHK_IND               VARCHAR   (1)     NULL
,CONFIG_POSN               SMALLINT        NULL
,CD_MRDS                   VARCHAR   (1)     NULL 
,CD_SMRS                   VARCHAR   (4)     NULL 
,SEQ_NUM_SMTR              SMALLINT        NULL 
,DBID_MGTY                 SMALLINT        NOT NULL 
,DBID_MGUT                 SMALLINT        NOT NULL 
,ID_ADDR                   INT         NULL 
,CHANGE_TRANSID            VARCHAR       (8)     NOT NULL
,CHANGE_TIMESTAMP          DECIMAL(20,6)   NOT NULL
,CHANGE_USERID             VARCHAR       (8)       NOT NULL
,CD_TPRG                               VARCHAR       (5)       NOT NULL
,ID_SMTY				 INT         NULL 
,EAC_CORE_MPAN_MPNT      BIGINT    NOT NULL 
,CALC_TS              DECIMAL(20,6)   NOT NULL
,EAC_NUM_MG              VARCHAR       (2)     NOT NULL 
,SETTLE_DT_EAC             DATETIME    NULL
,SETTLE_DT_AA              DATETIME    NULL
,MAP_END_DT                DATETIME    NULL
,EST_ANL_CNSMP             DECIMAL(   11,2)   NULL
,ANNLSD_ADVNC              DECIMAL(   11,2)   NULL
,INITIAL_IND               VARCHAR   (1)     NOT NULL
,D0052_IND                 VARCHAR   (1)    NOT NULL
,EAC_ID_NTME              BIGINT   NOT NULL 
,EAC_CHANGE_TRANSID            VARCHAR   (8)    NOT NULL
,EAC_CHANGE_TIMESTAMP          DECIMAL(20,6)   NOT NULL
,EAC_CHANGE_USERID             VARCHAR   (8)      NOT NULL
,WITHDRAWN_IND             VARCHAR   (1)      NOT NULL
,PEAK                                       VARCHAR   (1)      NOT NULL  DEFAULT 'N'            )

CREATE TABLE #MASTER_EAC
(
ID_ADDR                   INT				NOT NULL 
,ID_SA					  BIGINT			 NULL
,TOTAL_EST_ANL_CNSMP      DECIMAL(   11,2)   NULL
,PEAK_EST_ANL_CNSMP		  DECIMAL(   11,2)   NULL
,RATIO					  DECIMAL(   11,8)   NULL	)


 INSERT INTO #DRVR (CORE_MPAN_MPNT,ID_ADDR,ID_SA)
 
 SELECT 
    CORE_MPAN_MPNT
    ,ID_ADDR
    ,ID_SA
FROM 
MISUSERDATA.[UK\DC43967].PORTFOLIO_FOR_SMART_WASHES
WHERE MULTI_RATE_SITE='Y'      
AND
	NON_DOM='N'                                                                                                      


CREATE CLUSTERED INDEX IX_MPSA ON #DRVR(CORE_MPAN_MPNT,ID_ADDR,ID_SA)



INSERT INTO #TEMP (ID_NTME                  
                                                                  ,NUM_MG         )              


SELECT DISTINCT              

      EACA.[ID_NTME]
      ,EACA.[NUM_MG]
      
  FROM [dbo].[VCRO_EAC_AA]				EACA
  INNER JOIN
  #DRVR									DRVR
  ON DRVR.CORE_MPAN_MPNT=EACA.CORE_MPAN_MPNT
--WHERE CORE_MPAN_MPNT IN (SELECT CORE_MPAN_MPNT FROM #DRVR)  
--DRIVING TABLE OF DISTINCT SETTLEMENT REGISTER DETAILS


CREATE CLUSTERED INDEX IX_REG ON #TEMP (ID_NTME                                
                                                                  ,NUM_MG         )              
WITH (STATISTICS_NORECOMPUTE=ON)
--5 MINUTES TO HERE



INSERT INTO #MTR_REGISTER
(

[ID_NTME]                          
,[NUM]                                 
,[MULT_FCTR]                    
,[CAN_CHK_IND]              
,[CONFIG_POSN]             
,[CD_MRDS]                       
,[CD_SMRS]                        
,[SEQ_NUM_SMTR]         
,[DBID_MGTY]                   
,[DBID_MGUT]                   
,[ID_ADDR]                         
,[CD_TPRG]                         )


SELECT DISTINCT

MTRG.[ID_NTME]                             
,MTRG.[NUM]                                    
,MTRG.[MULT_FCTR]                      
,MTRG.[CAN_CHK_IND]                
,MTRG.[CONFIG_POSN]                
,MTRG.[CD_MRDS]                          
,MTRG.[CD_SMRS]                           
,MTRG.[SEQ_NUM_SMTR]            
,MTRG.[DBID_MGTY]                      
,MTRG.[DBID_MGUT]                     
,MTRG.[ID_ADDR]                            
,SMTS.CD_TPRG

FROM
#TEMP                                                                                  TEMP
INNER JOIN        
VCRO_NOTION_METER                                 NOMT
ON         NOMT.ID                             =TEMP.ID_NTME
INNER JOIN
VCRO_MTR_REGISTER                                    MTRG
ON         MTRG.ID_NTME                =TEMP.ID_NTME                              
AND
                MTRG.NUM                        =TEMP.NUM_MG
INNER JOIN
VCRO_SM_TYP_RUL_ST                                 SMTS
ON         SMTS.CD                              =CD_SMRS
WHERE
                NOMT.END_DT>@DECDATE
--CREATE SAR DATA TABLE FOR SETTLEMENT REGISTERS

INSERT INTO #FINAL_EACA(CORE_MPAN_MPNT      
						,CO_NUM              
						,ID_NTME            
						,NUM                 
						,MULT_FCTR           
						,CAN_CHK_IND         
						,CONFIG_POSN         
						,CD_MRDS             
						,CD_SMRS             
						,SEQ_NUM_SMTR        
						,DBID_MGTY           
						,DBID_MGUT           
						,ID_ADDR             
						,CHANGE_TRANSID      
						,CHANGE_TIMESTAMP    
						,CHANGE_USERID       
						,CD_TPRG  
						,ID_SMTY           
						,EAC_CORE_MPAN_MPNT  
						,CALC_TS             
						,EAC_NUM_MG          
						,SETTLE_DT_EAC       
						,SETTLE_DT_AA        
						,MAP_END_DT          
						,EST_ANL_CNSMP       
						,ANNLSD_ADVNC        
						,INITIAL_IND         
						,D0052_IND           
						,EAC_ID_NTME         
						,EAC_CHANGE_TRANSID  
						,EAC_CHANGE_TIMESTAMP
						,EAC_CHANGE_USERID   
						,WITHDRAWN_IND      ) 
SELECT DISTINCT

NOMT.CORE_MPAN_MPNT
,METR.CO_NUM
,MTRG.ID_NTME            
,MTRG.NUM                 
,MTRG.MULT_FCTR           
,MTRG.CAN_CHK_IND         
,MTRG.CONFIG_POSN         
,MTRG.CD_MRDS             
,MTRG.CD_SMRS             
,MTRG.SEQ_NUM_SMTR        
,MTRG.DBID_MGTY           
,MTRG.DBID_MGUT           
,MTRG.ID_ADDR             
,MTRG.CHANGE_TRANSID      
,MTRG.CHANGE_TIMESTAMP    
,MTRG.CHANGE_USERID       
,SMTS.CD_TPRG
,SMTS.ID_SMTY
,EACA.[CORE_MPAN_MPNT]
,EACA.[CALC_TS]
,EACA.[NUM_MG]
,EACA.[SETTLE_DT_EAC]
,EACA.[SETTLE_DT_AA]
,EACA.[MAP_END_DT]
,EACA.[EST_ANL_CNSMP]
,EACA.[ANNLSD_ADVNC]
,EACA.[INITIAL_IND]
,EACA.[D0052_IND]
,EACA.[ID_NTME]
,EACA.[CHANGE_TRANSID]
,EACA.[CHANGE_TIMESTAMP]
,EACA.[CHANGE_USERID]
,EACA.[WITHDRAWN_IND]

FROM
VCRO_NOTION_METER                                 NOMT--NOTIONAL METER RELATING TO PHYSICAL METER CONFIGURATION
INNER JOIN
VCRO_MTR_REGISTER                                    MTRG--PHYSICAL METER REGISTER
ON MTRG.ID_NTME=NOMT.ID   
INNER JOIN
VCRO_METER                                                                    METR
ON METR.ID                       =NOMT.ID_METR
INNER JOIN
VCRO_SM_TYP_RUL_ST                                 SMTS--SAR DATA FOR SERVICE MEASURE TYPE RULE SETS LINKED TO PHYICAL METER
ON SMTS.CD=CD_SMRS
INNER JOIN
#MTR_REGISTER                                                               SARM--SAR DATA FOR SETTLEMENTS REGISTERS CREATED IN THIS CODE
ON SARM.[CD_TPRG]=SMTS.CD_TPRG
INNER JOIN
VCRO_EAC_AA                                                                  EACA--EAC DATA HELD FOR SETTLEMENTS REGISTER
ON         EACA.ID_NTME=SARM.ID_NTME
AND
                EACA.NUM_MG                =SARM.NUM
AND
                EACA.CORE_MPAN_MPNT=NOMT.CORE_MPAN_MPNT
INNER JOIN
#DRVR					DRVR
ON DRVR.CORE_MPAN_MPNT= EACA.CORE_MPAN_MPNT               
INNER JOIN
(SELECT MAX(CALC_TS) CALC_TS
,EACA.CORE_MPAN_MPNT
,EACA.NUM_MG
,EACA.ID_NTME
FROM
VCRO_EAC_AA			EACA
INNER JOIN
#DRVR					DRVR
ON DRVR.CORE_MPAN_MPNT= EACA.CORE_MPAN_MPNT   
WHERE WITHDRAWN_IND='N'    
AND
[SETTLE_DT_EAC] IS NOT NULL       
AND
[EST_ANL_CNSMP] IS NOT NULL
GROUP BY
EACA.CORE_MPAN_MPNT
,EACA.NUM_MG
,EACA.ID_NTME)				EACAA
ON	EACAA.CORE_MPAN_MPNT=EACA.CORE_MPAN_MPNT
AND		 
	EACAA.NUM_MG		=EACA.NUM_MG	 
AND
	EACAA.ID_NTME		=EACA.ID_NTME
AND
	EACAA.CALC_TS		=EACA.CALC_TS
AND
	EACA.[SETTLE_DT_EAC] IS NOT NULL	
AND
	EACA.[EST_ANL_CNSMP] IS NOT NULL	

WHERE 
NOMT.END_DT>@DECDATE


UPDATE #FINAL_EACA SET PEAK='Y'
WHERE ID_SMTY IN (1001
,1002
,1004
,1008
,1012
,1013
,1014
,1015
,1018
,1033
,1035
,1041
,1042
,1044
,1046
,1050
,1066
,1068
,1072
,1077
,1091
,1092
,1094
,1095
,1096
,1120
,1121
,1126
,1132
,1174
,1175
,1176
,1177
,1191
,1193
,1195
,1198
,1199
,1200
,1202
,1207
,1208
,1209
,1211
,1220
,1221
,1222
,1227
,30060000
,70000000
,100001200
,150010001
,170000000
,210001200
,270010001
,320010001
,320060000
,330060000
,370000000
,370010001
,410001200
,450010001
,470010001
,500001200
,520060000
,540010001
,560000000
,570000000
,570010001
,600001200
,610001200
,640010001
,660000000
,670010001
,710001200
,720060000
,740010001
,860000000
,870000000
,900001200
,920060000
,930060000
,940010001
,950010001
,970010001
,270000000
)
--1 hour and 9 minutes


INSERT INTO #MASTER_EAC  (ID_ADDR                  
						  ,ID_SA           
						  ,TOTAL_EST_ANL_CNSMP     )
SELECT
 EACA.ID_ADDR
,DRVR.ID_SA
,SUM(EST_ANL_CNSMP)	

FROM


#FINAL_EACA			EACA
INNER JOIN
#DRVR				DRVR
ON DRVR.CORE_MPAN_MPNT=EACA.CORE_MPAN_MPNT
GROUP BY
 EACA.ID_ADDR
,DRVR.ID_SA

UPDATE #MASTER_EAC SET
PEAK_EST_ANL_CNSMP=DATA.EST_ANL_CNSMP
FROM
(SELECT
 EACA.ID_ADDR
,DRVR.ID_SA
,SUM(EST_ANL_CNSMP)			EST_ANL_CNSMP
FROM
#FINAL_EACA			EACA
INNER JOIN
#DRVR				DRVR
ON DRVR.CORE_MPAN_MPNT=EACA.CORE_MPAN_MPNT
WHERE PEAK='Y'
GROUP BY
 EACA.ID_ADDR
,DRVR.ID_SA
)DATA
WHERE 
#MASTER_EAC.ID_ADDR=DATA.ID_ADDR
AND
#MASTER_EAC.ID_SA=DATA.ID_SA

UPDATE #MASTER_EAC
SET PEAK_EST_ANL_CNSMP=0
WHERE PEAK_EST_ANL_CNSMP IS NULL

UPDATE #MASTER_EAC
SET TOTAL_EST_ANL_CNSMP=1
WHERE TOTAL_EST_ANL_CNSMP =0

UPDATE #MASTER_EAC
SET RATIO=  (TOTAL_EST_ANL_CNSMP-PEAK_EST_ANL_CNSMP)/TOTAL_EST_ANL_CNSMP

SELECT EACA.*

 FROM
#MASTER_EAC			EACA


