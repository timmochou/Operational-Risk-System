--P_ENTITY 測試參數：分行業務一處  /   處副主管(一處)  /   松山區   /   資訊長


--修改後d003 RISK_ALERT


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
),BRANCH AS(
--分行/分行層級所有資料
SELECT
        T1.DEPTID,
        T1.DEPT_NAME,
        CASE WHEN T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}' THEN SUM(T2.SCORE)
                ELSE 0
        END AS SCORE,
        '分行' AS DEPT_CATEGORY,
        '分行' AS DEPT_LEVEL
FROM "ODS_USR"."ORCD_TFBUNIT" T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID = T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND (T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-12) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-12) OR T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-24) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-24))
WHERE T1.DEPT_CATEGORY IS NOT NULL
AND T1.DEPT_LEVEL = '分行'
GROUP BY T1.DEPTID,T1.DEPT_NAME,T3.START_TIME,T3.END_TIME
),BRANCH_FINAL AS(
SELECT
        DEPTID,
        DEPT_NAME,
        DEPT_CATEGORY,
        DEPT_LEVEL,
        SUM(SCORE) AS SCORE
FROM BRANCH
GROUP BY
DEPTID,
DEPT_NAME,
DEPT_CATEGORY,
DEPT_LEVEL
),DIVISION_FINAL AS(
--分行/區層級所有資料
SELECT 
        T2.UPDEPTID AS DEPTID,
        T2.UPDEPT_NAME AS DEPT_NAME,
        '分行' AS DEPT_CATEGORY,
        '區' AS DEPT_LEVEL,
        CASE WHEN SUM(T1.SCORE) IS NULL THEN 0 
                ELSE SUM(T1.SCORE)
        END AS SCORE
FROM BRANCH_FINAL T1
LEFT JOIN "ODS_USR"."ORCD_TFBUNIT" T2
ON T1.DEPTID = T2.DEPTID
GROUP BY T2.UPDEPTID,T2.UPDEPT_NAME
),DEPARTMENT_FINAL AS(
--分行/處層級所有資料
SELECT 
        T2.UPDEPTID AS DEPTID,
        T2.UPDEPT_NAME AS DEPT_NAME,
        '分行' AS DEPT_CATEGORY,
        '處' AS DEPT_LEVEL,
        CASE WHEN SUM(T1.SCORE) IS NULL THEN 0 
               ELSE SUM(T1.SCORE)
        END AS SCORE
FROM DIVISION_FINAL T1
LEFT JOIN "ODS_USR"."ORCD_TFBUNIT" T2
ON T1.DEPTID = T2.DEPTID
GROUP BY T2.UPDEPTID,T2.UPDEPT_NAME
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
),HEADQUARTER AS(
--總行層級所有資料
SELECT
        T1.FATHER_ID AS DEPTID,
        T1.FATHER_NAME AS DEPT_NAME,
        CASE WHEN T3.START_TIME >= '${P_TIME_START}' AND T3.END_TIME <= '${P_TIME_END}' THEN SUM(T2.SCORE)
                ELSE 0
        END AS SCORE,
        '總行' AS DEPT_CATEGORY,
        '總行' AS DEPT_LEVEL
FROM HEADQUARTER_UNIT T1
LEFT JOIN "DM_T_VIEW"."FR_ORCD_SNAPSHOT" T2
ON T1.DEPTID = T2.DEPTID
LEFT JOIN ALL_TIME T3
ON T3.CATEGORY = '${P_TIME_UNIT}'
--前兩年同期
AND (T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-12) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-12) OR T2.DATA_DATE BETWEEN ADD_MONTHS(TO_DATE(T3.START_TIME,'yyyy-mm-dd'),-24) AND ADD_MONTHS(TO_DATE(T3.END_TIME,'yyyy-mm-dd'),-24))
WHERE 1=1
GROUP BY T1.FATHER_ID,T1.FATHER_NAME,T3.START_TIME,T3.END_TIME
),HEADQUARTER_FINAL AS(
SELECT
        DEPTID,
        DEPT_NAME,
        DEPT_CATEGORY,
        DEPT_LEVEL,
        SUM(SCORE) AS SCORE
FROM HEADQUARTER
GROUP BY
DEPTID,
DEPT_NAME,
DEPT_CATEGORY,
DEPT_LEVEL
),ALL_DEPT AS(
SELECT * FROM BRANCH_FINAL
UNION ALL
SELECT * FROM DIVISION_FINAL
UNION ALL
SELECT * FROM DEPARTMENT_FINAL
UNION ALL
SELECT * FROM HEADQUARTER_FINAL
),BASE AS(
--匹配該層級所有資料
SELECT
        ROW_NUMBER() OVER(ORDER BY T1.SCORE DESC) ROW_NUM,
        T1.DEPTID,
        T2.DEPT_NAME,
     SCORE
--      CASE WHEN T1.SCORE>'${P_LIMIT}' THEN ${P_LIMIT}
--              ELSE T1.SCORE END AS SCORE
FROM ALL_DEPT T1
LEFT JOIN "ODS_USR"."ORCD_TFBUNIT" T2
ON T1.DEPTID = T2.DEPTID
WHERE 1=1
${IF(LEN(P_ENTITY_UNIT)=0,"","AND T1.DEPT_CATEGORY = '" + P_ENTITY_UNIT + "'")} 
${IF(LEN(P_ENTITY)=0,"","AND T1.DEPT_LEVEL = '" + P_ENTITY + "'")} 
),TOP50_DATA AS(
--前50%資料
SELECT
        *
FROM BASE
WHERE ROW_NUM <= (SELECT 0.5*COUNT(*) FROM BASE)
),BOT50_DATA AS(
--後50%資料
SELECT
        *
FROM BASE
WHERE ROW_NUM > (SELECT 0.5*COUNT(*) FROM BASE)
)
--危險值
SELECT
        --總分
        SUM(SCORE)/2,
        --單位數
        COUNT(DEPT_NAME),
        --平均數
        SUM(SCORE)/(COUNT(DEPT_NAME)*2)
FROM TOP50_DATA T1
UNION ALL
--預警值
SELECT
        --總分
        SUM(SCORE)/2,
        --單位數
        COUNT(DEPT_NAME),
        --平均數
        SUM(SCORE)/(COUNT(DEPT_NAME)*2)
FROM BOT50_DATA