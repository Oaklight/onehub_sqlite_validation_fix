-- Log Quota Comparison Query
-- 价格计算公式: quota * 0.002 / 1000 = price (单位: USD)
-- 本查询对比通过logs计算得到的quota与logs中记录的quota，并展示差异，同时输出价格信息

WITH header AS (
    SELECT 
        0 AS sort_order,
        printf("%-10s", "User ID")          AS "User ID",
        printf("%-15s", "Username")          AS "Username",
        printf("%15s", "Calculated Quota")   AS "Calculated Quota",
        printf("%15s", "Log Quota")          AS "Log Quota",
        printf("%15s", "Difference")         AS "Difference",
        printf("%10s", "Calc Price")          AS "Calc Price",
        printf("%10s", "Log Price")           AS "Log Price",
        printf("%10s", "Price Diff")          AS "Price Diff"
),
data AS (
    SELECT 
        1 AS sort_order,
        printf("%-10d", l.user_id) AS "User ID",
        printf("%-15s", u.username) AS "Username",
        printf("%15d", SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input)
                ELSE CEIL(l.prompt_tokens * p.input + l.completion_tokens * p.output)
            END
        )) AS "Calculated Quota",
        printf("%15d", SUM(l.quota)) AS "Log Quota",
        printf("%15d", SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input)
                ELSE CEIL(l.prompt_tokens * p.input + l.completion_tokens * p.output)
            END
        ) - SUM(l.quota)) AS "Difference",
        printf("%10.3f", SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input)
                ELSE CEIL(l.prompt_tokens * p.input + l.completion_tokens * p.output)
            END
        ) * 0.002/1000) AS "Calc Price",
        printf("%10.3f", SUM(l.quota) * 0.002/1000) AS "Log Price",
        printf("%10.3f", (SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input)
                ELSE CEIL(l.prompt_tokens * p.input + l.completion_tokens * p.output)
            END
        ) * 0.002/1000) - (SUM(l.quota) * 0.002/1000)) AS "Price Diff"
    FROM 
        logs l
    JOIN 
        prices p ON l.model_name = p.model
    JOIN 
        users u ON l.user_id = u.id
    GROUP BY 
        l.user_id, u.username
)
SELECT "User ID", "Username", "Calculated Quota", "Log Quota", "Difference", "Calc Price", "Log Price", "Price Diff"
FROM (
    SELECT * FROM header
    UNION ALL
    SELECT * FROM data
)
ORDER BY sort_order, "User ID" DESC;
