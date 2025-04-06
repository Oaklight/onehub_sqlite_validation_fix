-- Log Quota Comparison Query (Updated)
-- 价格计算公式: price = quota * 0.002 / 1000 (单位: USD)
-- 计算逻辑：先计算原始price，再除以0.000002向上取整，再乘回0.000002，即
-- price = CEIL((原始price) / 0.000002) * 0.000002
-- 注意：原始price的计算采用开发者给出的公式：
-- quota = CEIL(prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
--              completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
-- 本查询对比通过logs计算得到的quota（使用新公式）与logs中记录的quota，并展示差异，同时输出价格信息

WITH header AS (
    SELECT 
        0 AS sort_order,
        printf("%-10s", "User ID")             AS "User ID",
        printf("%-15s", "Username")             AS "Username",
        printf("%15s", "Calculated Quota")      AS "Calculated Quota",
        printf("%15s", "Log Quota")             AS "Log Quota",
        printf("%15s", "Difference")            AS "Difference",
        printf("%12s", "Calc Price (USD)")       AS "Calc Price (USD)",
        printf("%12s", "Log Price (USD)")        AS "Log Price (USD)",
        printf("%12s", "Price Diff (USD)")       AS "Price Diff (USD)"
),
data AS (
    SELECT 
        1 AS sort_order,
        printf("%-10d", l.user_id)                   AS "User ID",
        printf("%-15s", u.username)                   AS "Username",
        /* 采用新公式计算Calculated Quota */
        printf("%15d", SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        )) AS "Calculated Quota",
        printf("%15d", SUM(l.quota))                  AS "Log Quota",
        printf("%15d", SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        ) - SUM(l.quota))                              AS "Difference",
        /* 计算价格采用新计算得到的Calculated Quota */
        printf("%12.6f", CEIL((SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        ) * 0.002/1000) / 0.000002) * 0.000002)     AS "Calc Price (USD)",
        printf("%12.6f", CEIL((SUM(l.quota) * 0.002/1000) / 0.000002) * 0.000002) AS "Log Price (USD)",
        printf("%12.6f", 
            CEIL((SUM(
                CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                     l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            ) * 0.002/1000) / 0.000002) * 0.000002 - 
            CEIL((SUM(l.quota) * 0.002/1000) / 0.000002) * 0.000002
        ) AS "Price Diff (USD)"
    FROM 
        logs l
    JOIN 
        prices p ON l.model_name = p.model
    JOIN 
        users u ON l.user_id = u.id
    GROUP BY 
        l.user_id, u.username
)
SELECT "User ID", "Username", "Calculated Quota", "Log Quota", "Difference", "Calc Price (USD)", "Log Price (USD)", "Price Diff (USD)"
FROM (
    SELECT * FROM header
    UNION ALL
    SELECT * FROM data
)
ORDER BY sort_order, "User ID" DESC;
