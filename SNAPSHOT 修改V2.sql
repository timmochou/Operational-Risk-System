WITH AUDITNUM_ETL AS(

   SELECT

          DOCUMENT_NO AS REFID,

            UNIT_CODE,

            DATE_REPORT,

           TO_NUMBER(RISK_EXTREME) AS RISK_EXTREME,

           TO_NUMBER(RISK_HIGH) AS RISK_HIGH,

           TO_NUMBER(RISK_MEDHIGH) AS RISK_MEDHIGH,

           TO_NUMBER(RISK_MEDIUM) AS RISK_MEDIUM,

           TO_NUMBER(RISK_LOW) AS RISK_LOW


   FROM "ODS_USR"."ORCD_AUDITNUM" T1

   LEFT JOIN "ODS_USR"."ORCD_TFBUNIT" T2

   ON T1.UNIT_CODE = T2.DEPTID

   ),DATA AS(

   SELECT

          REFID,

            DEPARTMENT_CODE AS DEPTID,  --分行代碼

            DATA_ENDDT AS DATA_DATE,  --資料日期

           'KRI' AS CATEGORY,

           CASE WHEN RED != 0 THEN '紅燈'

                   WHEN YELLOW != 0 THEN '黃燈'

            END AS NAME,

           CASE WHEN RED != 0 THEN RED

                   WHEN YELLOW != 0 THEN YELLOW

            END AS AMOUNT,

           CASE WHEN RED != 0 THEN RED

                   WHEN YELLOW != 0 THEN YELLOW

            END AS SCORECOUNT

   FROM "ODS_USR"."ORCD_KRI"

   UNION ALL

   SELECT

          REFID,

            UNIT_CODE AS DEPTID,

           TO_TIMESTAMP(DATE_SELF_INSPECT,'YYYY/MM/DD') AS DATA_DATE,  --20230913 修改

           'CSA' AS CATEGORY,

           CASE WHEN RED != 0 THEN '紅燈'

                   WHEN YELLOW != 0 THEN '黃燈'

            END AS NAME,

           CASE WHEN RED != 0 THEN RED

                   WHEN YELLOW != 0 THEN YELLOW

           END AS AMOUNT,

           CASE WHEN RED != 0 THEN RED

                   WHEN YELLOW != 0 THEN YELLOW

           END AS SCORECOUNT

   FROM "ODS_USR"."ORCD_CSA"

   UNION ALL

   SELECT

          LOSSEVENT_NO AS REFID,

            UNIT_CODE AS DEPTID,

            DATE_CREATE AS DATA_DATE,

           'LDC' AS CATEGORY,

            CASE WHEN INCIDENT = '是' AND GOV_PUNISHMENT = '是' THEN '重偶風險事件'
                WHEN INCIDENT = '否' AND GOV_PUNISHMENT = '是' THEN '重要風險事件'
                WHEN INCIDENT = '否' AND GOV_PUNISHMENT = '否' AND (100000 <= MAX_IMPACT_AMT AND MAX_IMPACT_AMT*PERCENTAGE < 500000) THEN '一般風險事件B'
                WHEN INCIDENT = '否' AND GOV_PUNISHMENT = '否' AND (0 <= MAX_IMPACT_AMT AND MAX_IMPACT_AMT*PERCENTAGE < 100000) THEN '一般風險事件C'
                ELSE '一般風險事件A'
            END AS NAME,

           CASE WHEN DISCOUNT IS NULL THEN '0' 
                ELSE TO_CHAR(TO_NUMBER(PERCENTAGE) * TO_NUMBER(DISCOUNT))
           END AS AMOUNT,

           PERCENTAGE AS SCORECOUNT

   FROM "ODS_USR"."ORCD_LDC"

   WHERE LOSSEVENT_LV1 != '外部詐欺'

   AND CASE_STATUS != '草稿'

   AND CASE_STATUS != '無效'

   UNION ALL

   SELECT

          DOCID AS REFID,

            UNIT_CODE AS DEPTID,

            DATE_HANDLE AS DATA_DATE,

           '客訴事件' AS CATEGORY,

           CASE WHEN AGAINST_FAIR_TREAT = '是' THEN '違反公平待客原則'

            WHEN (AGAINST_FAIR_TREAT = '否' OR AGAINST_FAIR_TREAT IS NULL) AND WMISTAKE = '有' THEN '本行疏失' 

             WHEN (AGAINST_FAIR_TREAT = '否' OR AGAINST_FAIR_TREAT IS NULL) AND (WMISTAKE = '無' OR WMISTAKE IS NULL) THEN '其他' END AS NAME,

           '1' AS AMOUNT,

           '1' AS SCORECOUNT

   FROM "DM_T_VIEW"."FR_ORCD_COMPLAINT"

   WHERE UNIT_CODE != 'BUTTW01782' --公平待客部

   UNION ALL

   SELECT

          REFID,

            UNIT_CODE AS DEPTID,

            DATE_REPORT AS DATA_DATE,

           '稽核缺失' AS CATEGORY,

            COLUMN_NAME AS NAME,

           TO_CHAR(VALUE) AS AMOUNT,

           TO_CHAR(VALUE) AS SCORECOUNT

   FROM AUDITNUM_ETL

   UNPIVOT(

           VALUE

           FOR COLUMN_NAME IN(RISK_EXTREME AS '重大風險',RISK_HIGH AS '高風險',RISK_MEDHIGH AS '中高風險',RISK_MEDIUM AS '中風險',RISK_LOW AS '低風險')

           )

   ),MAX_VERSION AS(

   SELECT

           CATEGORY,

           NAME,

            WEIGHT,

           SCORE,

           VERSION

   FROM "ODS_USR"."ORCD_SCORERULE"

   WHERE VERSION = (SELECT MAX(VERSION) FROM "ODS_USR"."ORCD_SCORERULE")

   )

   SELECT  SYSDATE SNAP_DATE,  --v_Snap_Date

          T1.REFID,

            T1.DEPTID,

            T1.DATA_DATE,

            T1.CATEGORY,

            T1.NAME,

            T1.SCORECOUNT AS SCORECOUNT,


           CASE 
           WHEN T1.CATEGORY = '稽核缺失' AND (T1.NAME = ' 中風險' OR T1.NAME = '低風險')AND T3.DEPT_GRADE = 'A' THEN (T1.AMOUNT*T2.WEIGHT*T2.SCORE*0.5)
                WHEN T1.CATEGORY = '稽核缺失' AND (T1.NAME = ' 中風險' OR T1.NAME = '低風險')AND T3.DEPT_GRADE = 'B' THEN (T1.AMOUNT*T2.WEIGHT*T2.SCORE*0.75)
                WHEN T1.CATEGORY = '稽核缺失' AND (T1.NAME = ' 中風險' OR T1.NAME = '低風險')AND T3.DEPT_GRADE = 'c' THEN (T1.AMOUNT*T2.WEIGHT*T2.SCORE*1)
                WHEN T1.AMOUNT*T2.WEIGHT*T2.SCORE IS NULL THEN 0
                   ELSE T1.AMOUNT*T2.WEIGHT*T2.SCORE

            END AS SCORE,

           NULL TRANS_SN,

           sysdate EXEC_DATE,

           T2.VERSION

   FROM DATA T1

   LEFT JOIN MAX_VERSION T2

    ON T1.CATEGORY = T2.CATEGORY

   AND T1.NAME = T2.NAME

    LEFT JOIN "ODS_USR"."ORCD_TFBUNIT" T3

  ON T1.DEPTID = T3.DEPTID