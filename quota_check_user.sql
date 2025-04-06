-- User Quota Comparison Query
-- 价格计算公式: price = quota * 0.002 / 1000 (单位: USD)
-- 计算逻辑：先计算原始价格，然后除以0.000002向上取整，再乘回0.000002，即
-- price = CEIL((原始price) / 0.000002) * 0.000002
-- 注意：原始price的计算不再使用p.input和p.output，而是使用l.metadata中的input_ratio和output_ratio
-- 本查询对比users表中的used_quota与通过logs计算得到的quota，并展示差异，同时输出价格信息

WITH header AS (
    SELECT 
        0 AS sort_order,
        printf("%-10s", "User ID")            AS "User ID",
        printf("%-15s", "Username")            AS "Username",
        printf("%15s", "Calculated Quota")     AS "Calculated Quota",
        printf("%15s", "User Used Quota")       AS "User Used Quota",
        printf("%15s", "Difference")            AS "Difference",
        printf("%12s", "Calc Price (USD)")       AS "Calc Price (USD)",
        printf("%12s", "User Price (USD)")       AS "User Price (USD)",
        printf("%12s", "Price Diff (USD)")       AS "Price Diff (USD)"
),
data AS (
    SELECT 
        1 AS sort_order,
        printf("%-10d", u.id) AS "User ID",
        printf("%-15s", u.username) AS "Username",
        printf("%15d", SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * JSON_EXTRACT(l.metadata, '$.input_ratio')
                ELSE CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            END
        )) AS "Calculated Quota",
        printf("%15d", u.used_quota) AS "User Used Quota",
        printf("%15d", u.used_quota - SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * JSON_EXTRACT(l.metadata, '$.input_ratio')
                ELSE CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            END
        )) AS "Difference",
        printf("%12.6f", CEIL((SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * JSON_EXTRACT(l.metadata, '$.input_ratio')
                ELSE CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            END
        ) * 0.002/1000) / 0.000002) * 0.000002) AS "Calc Price (USD)",
        printf("%12.6f", CEIL((u.used_quota * 0.002/1000) / 0.000002) * 0.000002) AS "User Price (USD)",
        printf("%12.6f", CEIL((u.used_quota * 0.002/1000) / 0.000002) * 0.000002 - CEIL((SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * JSON_EXTRACT(l.metadata, '$.input_ratio')
                ELSE CEIL(l.prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
            END
        ) * 0.002/1000) / 0.000002) * 0.000002) AS "Price Diff (USD)"
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
