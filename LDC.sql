WITH DEPT_BASE AS(
--組織基底
SELECT
        N'全行' AS DEPT_NAME,
        N'0000' AS UPDEPT_NAME,
        N'0001' AS DEPTID,
        N'0000' AS UPDEPTID
FROM DUAL
UNION ALL
SELECT
        N'總行' AS DEPT_NAME,
        N'全行' AS UPDEPT_NAME,
        N'0002' AS DEPTID,
        N'0001' AS UPDEPTID
FROM DUAL
UNION ALL
SELECT
        N'分行' AS DEPT_NAME,
        N'全行' AS UPDEPT_NAME,
        N'0003' AS DEPTID,
        N'0001' AS UPDEPTID
FROM DUAL
),DEPT_SYS AS(
--結合系統組織
SELECT
        DEPT_NAME,
        UPDEPT_NAME,
        DEPTID,
        UPDEPTID
FROM DEPT_BASE
UNION ALL
SELECT
        DEPT_NAME,
        CASE WHEN  DEPT_NAME LIKE '分行%處' THEN N'分行'
                WHEN PARENT_NODE_NAME = 'BUTTW00016' THEN N'總行'
                ELSE UPDEPT_NAME END AS UPDEPT_NAME,
        DEPTID,
        CASE WHEN  DEPT_NAME LIKE '分行%處' THEN N'0003'
                WHEN PARENT_NODE_NAME = 'BUTTW00016' THEN N'0002'
                ELSE PARENT_NODE_NAME END AS UPDEPTID
FROM "ODS_BANK"."DG_HRIS_BUDEPT"
WHERE SETID = 'BUTTW'
),DEPT_TREE AS(
--組成組織樹
SELECT 
        DEPTID,
        DEPT_NAME,
        UPDEPTID,
        UPDEPT_NAME,
        CONNECT_BY_ROOT(DEPT_NAME) AS FATHER,
        CONNECT_BY_ROOT(DEPTID) AS FATHER_ID
FROM DEPT_SYS
START WITH DEPT_NAME = '${P_ENTITY}'
CONNECT BY PRIOR DEPTID = UPDEPTID
),ALL_TIME AS(
--今年1月～當前月+前五年所有月份
SELECT 
        'monthly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 1),'yyyy-mm') AS DATA_DATE,
        ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 1) AS START_TIME,
        ADD_MONTHS(TRUNC(SYSDATE,'mm'),-ROWNUM + 2)-1 AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'mm') + 60
UNION ALL
--今年第1季～當前季+前五年所有季
SELECT 
        'quarterly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +3),'yyyy-"Q"q') AS DATA_DATE,
        ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +3) AS START_TIME,
        ADD_MONTHS(TRUNC(SYSDATE,'q'),-ROWNUM*3 +6)-1 AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'q') + 20
UNION ALL
--今年H1(+H2)+前五年中所有半年
SELECT 
        'half-yearly' AS CATEGORY,
        CONCAT(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +6),'yyyy-"H"'),
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +12)-1,'mm')/6) AS DATA_DATE,
        ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +6) AS START_TIME,
        ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*6 +12)-1 AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <= TO_CHAR(SYSDATE,'q')/2 + 10
UNION ALL
--當前年+前五年
SELECT 
        'yearly' AS CATEGORY,
        TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +12),'yyyy') AS DATA_DATE,
        ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +12) AS START_TIME,
        ADD_MONTHS(TRUNC(SYSDATE,'yyyy'),-ROWNUM*12 +24)-1 AS END_TIME
FROM DUAL
CONNECT BY ROWNUM <=  6
)
--串LDC資料
SELECT
        T3.DATA_DATE AS RANGE,
        '預估損失金額' AS NAME,
--
CASE WHEN SUM(MAX_IMPACT_AMT) IS NULL THEN 0
	ELSE SUM(MAX_IMPACT_AMT*PERCENTAGE) END AS AMT
FROM
DEPT_TREE T1
LEFT JOIN 
"ODS_USR"."ORCD_LDC" T2
ON T1.DEPTID = T2.UNIT_CODE
AND T2.CASE_STATUS != '草稿' 
AND T2.CASE_STATUS != '無效' 
RIGHT JOIN
ALL_TIME T3
ON
T2.DATE_CREATE BETWEEN T3.START_TIME AND T3.END_TIME
WHERE 1=1
AND T3.CATEGORY = '${P_TIME_UNIT}'
${IF(LEN(P_TIME_START)=0,"","AND T3.DATA_DATE >= '" + P_TIME_START + "'")} 
${IF(LEN(P_TIME_END)=0,"","AND T3.DATA_DATE <= '" + P_TIME_END + "'")}
GROUP BY T3.DATA_DATE
UNION ALL
SELECT
        T3.DATA_DATE AS RANGE,
        '損失金額' AS NAME,
--
CASE WHEN SUM(NET_LOSS) IS NULL THEN 0
	ELSE SUM(NET_LOSS*PERCENTAGE) END AS AMT
FROM
DEPT_TREE T1
LEFT JOIN 
"ODS_USR"."ORCD_LDC" T2
ON T1.DEPTID = T2.UNIT_CODE
AND T2.CASE_STATUS != '草稿' 
AND T2.CASE_STATUS != '無效' 
RIGHT JOIN
ALL_TIME T3
ON
T2.DATE_CLOSE BETWEEN T3.START_TIME AND T3.END_TIME
WHERE 1=1
AND T3.CATEGORY = '${P_TIME_UNIT}'
${IF(LEN(P_TIME_START)=0,"","AND T3.DATA_DATE >= '" + P_TIME_START + "'")} 
${IF(LEN(P_TIME_END)=0,"","AND T3.DATA_DATE <= '" + P_TIME_END + "'")}
GROUP BY T3.DATA_DATE
ORDER BY
RANGE