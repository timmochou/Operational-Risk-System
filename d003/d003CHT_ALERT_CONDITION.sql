--SELECT * FROM "ODS_USR"."ORCD_TFBUNIT"
--SELECT * FROM "DM_T_VIEW"."FR_ORCD_SNAPSHOT"

--d003 alert_condition

WITH ALL_TIME AS(
--今年1月～當前月+前五年所有月份
SELECT 
        'monthly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 1),'yyyy-mm') AS DATA_DATE,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 1),'yyyy-mm-dd') AS START_TIME,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 2)-1,'yyyy-mm-dd') AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'mm') + 60
UNION ALL
--今年第1季～當前季+前五年所有季
SELECT 
        'quarterly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +3),'yyyy-"Q"q') AS DATA_DATE,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +3),'yyyy-mm-dd') AS START_TIME,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +6)-1,'yyyy-mm-dd') AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'q') + 20
UNION ALL
--今年H1(+H2)+前五年中所有半年
SELECT 
        'half-yearly' AS CATEGORY,
        CONCAT(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +6),'yyyy-"H"'),
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +12)-1,'mm')/6) AS DATA_DATE,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +6),'yyyy-mm-dd') AS START_TIME,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +12)-1,'yyyy-mm-dd') AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'q')/2 + 10
UNION ALL
--當前年+前五年
SELECT 
        'yearly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +12),'yyyy') AS DATA_DATE,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +12),'yyyy-mm-dd') AS START_TIME,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +24)-1,'yyyy-mm-dd') AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <=  6
),BRANCH_1 AS(
SELECT
        'TIME_ZONE_1' AS TIME_ZONE,
        SUM(T2.SCORE) AS SCORE
FROM "ODS_USR"."ORCD_TFBUNIT" T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID=T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-12) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-12)
WHERE T1.DEPT_CATEGORY IS NOT NULL
AND T1.DEPT_LEVEL = '分行'
AND T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}'
),BRANCH_2 AS(
SELECT
        'TIME_ZONE_2' AS TIME_ZONE,
        SUM(T2.SCORE) AS SCORE
FROM "ODS_USR"."ORCD_TFBUNIT" T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID=T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-24) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-24)
WHERE T1.DEPT_CATEGORY IS NOT NULL
AND T1.DEPT_LEVEL = '分行'
AND T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}'
),BRANCH_FINAL AS(
SELECT 
        TIME_ZONE,
        SCORE,
        '分行' AS CATEGORY
FROM BRANCH_1
UNION ALL
SELECT 
        TIME_ZONE,
        SCORE,
        '分行' AS CATEGORY
FROM BRANCH_2
),HEADQUARTER_UNIT AS(
--總行單位彙整到部處層級
SELECT 
        DEPTID,
        DEPT_NAME,
        UPDEPTID,
        UPDEPT_NAME,
        CONNECT_BY_ROOT(DEPT_NAME) AS FATHER_NAME,
        CONNECT_BY_ROOT(DEPTID) AS FATHER_ID
FROM ODS_USR.ORCD_TFBUNIT
--若為最底層單位則保留原單位，非最底層單位則尋找下階單位
START WITH DEPT_LEVEL = '總行'
CONNECT BY PRIOR DEPTID = UPDEPTID
),HEADQUARTER_1 AS(
SELECT
        'TIME_ZONE_1' AS TIME_ZONE,
        SUM(T2.SCORE) AS SCORE
FROM HEADQUARTER_UNIT T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID=T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-12) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-12)
WHERE 1=1
AND T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}'
),HEADQUARTER_2 AS(
SELECT
        'TIME_ZONE_2' AS TIME_ZONE,
        SUM(T2.SCORE) AS SCORE
FROM HEADQUARTER_UNIT T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID=T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-24) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-24)
WHERE 1=1
AND T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}'
),HEADQUARTER_FINAL AS(
SELECT 
        TIME_ZONE,
        SCORE,
        '總行' AS CATEGORY
FROM HEADQUARTER_1
UNION ALL
SELECT 
        TIME_ZONE,
        SCORE,
        '總行' AS CATEGORY
FROM HEADQUARTER_2
),FINAL AS(
SELECT 
        TIME_ZONE,
        SCORE,
        CATEGORY
FROM BRANCH_FINAL
UNION
SELECT 
        TIME_ZONE,
        SCORE,
        CATEGORY
FROM HEADQUARTER_FINAL
)
SELECT
        COUNT(SCORE)
FROM FINAL
WHERE CATEGORY = '${P_ENTITY_UNIT}'
AND SCORE IS NOT NULL