-- User Quota Comparison Query (Updated with new formula)
-- 价格计算公式: price = quota * 0.002 / 1000 (单位: USD)
-- 计算逻辑：先根据新的公式计算quota，再计算原始price，
-- 然后除以0.000002向上取整，再乘回0.000002，即：
-- price = CEIL((原始price) / 0.000002) * 0.000002
-- 新的quota计算公式：
--   quota = CEIL(prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
--                completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
-- 本查询对比users表中的used_quota与通过logs计算得到的quota（使用新公式），
-- 并展示差异，同时输出价格信息。

WITH header AS (
    SELECT 
        0 AS sort_order,
        printf("%-10s", "User ID")             AS "User ID",
        printf("%-15s", "Username")             AS "Username",
        printf("%15s", "Calculated Quota")      AS "Calculated Quota",
        printf("%15s", "User Used Quota")        AS "User Used Quota",
        printf("%15s", "Difference")             AS "Difference",
        printf("%12s", "Calc Price (USD)")        AS "Calc Price (USD)",
        printf("%12s", "User Price (USD)")        AS "User Price (USD)",
        printf("%12s", "Price Diff (USD)")        AS "Price Diff (USD)"
),
data AS (
    SELECT 
        1 AS sort_order,
        printf("%-10d", u.id)                       AS "User ID",
        printf("%-15s", u.username)                 AS "Username",
        /* 使用新公式计算Calculated Quota */
        printf("%15d", SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        )) AS "Calculated Quota",
        printf("%15d", u.used_quota)                AS "User Used Quota",
        /* 差异 = used_quota - 通过logs计算的quota */
        printf("%15d", u.used_quota - SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        )) AS "Difference",
        /* 计算价格: 先根据通过logs计算的quota计算原始价格，再按最小计量0.000002向上取整 */
        printf("%12.6f", CEIL((SUM(
            CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                 l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
        ) * 0.002/1000) / 0.000002) * 0.000002)   AS "Calc Price (USD)",
        printf("%12.6f", CEIL((u.used_quota * 0.002/1000) / 0.000002) * 0.000002) AS "User Price (USD)",
        printf("%12.6f", 
            CEIL((u.used_quota * 0.002/1000) / 0.000002) * 0.000002 - 
            CEIL((SUM(
                CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
                     l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            ) * 0.002/1000) / 0.000002) * 0.000002
        ) AS "Price Diff (USD)"
    FROM 
        logs l
    JOIN 
        prices p ON l.model_name = p.model
    JOIN 
        users u ON l.user_id = u.id
    GROUP BY 
        u.id, u.username, u.used_quota
)
SELECT "User ID", "Username", "Calculated Quota", "User Used Quota", "Difference", "Calc Price (USD)", "User Price (USD)", "Price Diff (USD)"
FROM (
    SELECT * FROM header
    UNION ALL
    SELECT * FROM data
)
ORDER BY sort_order, "User ID" DESC;
