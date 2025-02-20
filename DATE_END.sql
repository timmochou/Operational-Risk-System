WITH ALL_TIME AS(
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
SELECT
        --CATEGORY,
        DATA_DATE,
        START_TIME
        --END_TIME
FROM ALL_TIME
WHERE CATEGORY = '${P_TIME_UNIT}'
${IF(LEN(P_TIME_START)=0,"","AND DATA_DATE >= '" + P_TIME_START + "'")}
${IF(P_TIME_UNIT='yearly',"AND DATA_DATE BETWEEN '"+P_TIME_START+"' AND TO_CHAR(ADD_MONTHS(TO_DATE('"+P_TIME_START+"','yyyy'),12),'YYYY')","")}
${IF(P_TIME_UNIT='half-yearly', "AND DATA_DATE = '" + P_TIME_START + "'", "")}
${IF(P_TIME_UNIT='monthly',"AND DATA_DATE BETWEEN '"+P_TIME_START+"' AND TO_CHAR(ADD_MONTHS(TO_DATE('"+P_TIME_START+"','yyyy-mm'),12),'YYYY-MM')","")}
ORDER BY DATA_DATE DESC