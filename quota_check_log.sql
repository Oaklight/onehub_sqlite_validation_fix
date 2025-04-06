-- Log Quota Comparison Query (Updated)
-- 价格计算公式: price = quota * 0.002 / 1000 (单位: USD)
-- 计算逻辑：先计算原始price，再除以0.000002向上取整，再乘回0.000002，即
-- price = CEIL((原始price) / 0.000002) * 0.000002
-- 注意：原始price的计算采用开发者给出的公式：
-- quota = CEIL(prompt_tokens * JSON_EXTRACT(l.metadata, '$.input_ratio') + 
--              completion_tokens * JSON_EXTRACT(l.metadata, '$.output_ratio'))
-- 本查询对比通过logs计算得到的quota（使用新公式）与logs中记录的quota，并展示差异，同时输出价格信息
WITH
    header AS (
        SELECT
            0 AS sort_order,
            printf ("%-8s", "UserID") AS "UserID",
            printf ("%-12s", "Username") AS "Username",
            printf ("%8s", "Queries") AS "Queries",
            printf ("%8s", "Null") AS "Null",
            printf ("%12s", "Calc Quota") AS "Calc Quota",
            printf ("%12s", "Log Quota") AS "Log Quota",
            printf ("%12s", "Diff") AS "Diff",
            printf ("%10s", "Calc $") AS "Calc $",
            printf ("%10s", "Log $") AS "Log $",
            printf ("%10s", "Diff $") AS "Diff $"
    ),
    data AS (
        SELECT
            1 AS sort_order,
            printf ("%-8d", l.user_id) AS "UserID",
            printf ("%-12s", u.username) AS "Username",
            printf ("%8d", COUNT(*)) AS "Queries",
            printf ("%8d", SUM(CASE WHEN l.quota IS NULL THEN 1 ELSE 0 END)) AS "Null",
            printf (
                "%12d",
                SUM(
                    CEIL(
                        l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                    )
                )
            ) AS "Calc Quota",
            printf ("%12d", SUM(l.quota)) AS "Log Quota",
            printf (
                "%12d",
                SUM(
                    CEIL(
                        l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                    )
                ) - SUM(l.quota)
            ) AS "Diff",
            /* 计算价格采用新计算得到的Calculated Quota */
            printf (
                "%10.6f",
                CEIL(
                    (
                        SUM(
                            CEIL(
                                l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                            )
                        ) * 0.002 / 1000
                    ) / 0.000002
                ) * 0.000002
            ) AS "Calc $",
            printf (
                "%10.6f",
                CEIL((SUM(l.quota) * 0.002 / 1000) / 0.000002) * 0.000002
            ) AS "Log $",
            printf (
                "%10.6f",
                CEIL(
                    (
                        SUM(
                            CEIL(
                                l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                            )
                        ) * 0.002 / 1000
                    ) / 0.000002
                ) * 0.000002 - CEIL((SUM(l.quota) * 0.002 / 1000) / 0.000002) * 0.000002
            ) AS "Diff $"
        FROM
            logs l
            JOIN prices p ON l.model_name = p.model
            JOIN users u ON l.user_id = u.id
        GROUP BY
            l.user_id,
            u.username
    )
SELECT
    "UserID",
    "Username",
    "Queries",
    "Null",
    "Calc Quota",
    "Log Quota",
    "Diff",
    "Calc $",
    "Log $",
    "Diff $"
FROM
    (
        SELECT
            *
        FROM
            header
        UNION ALL
        SELECT
            *
        FROM
            data
    )
ORDER BY
    sort_order,
    "UserID" ASC;
