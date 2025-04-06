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
WITH
    header AS (
        SELECT
            0 AS sort_order,
            printf ("%-8s", "UserID") AS "UserID",
            printf ("%-12s", "Username") AS "Username",
            printf ("%8s", "Queries") AS "Queries",
            printf ("%12s", "Total Quota") AS "Total Quota",
            printf ("%12s", "Calc Quota") AS "Calc Quota", 
            printf ("%12s", "Used Quota") AS "Used Quota",
            printf ("%12s", "Diff") AS "Diff",
            printf ("%10s", "Total $") AS "Total $",
            printf ("%10s", "Calc $") AS "Calc $",
            printf ("%10s", "Used $") AS "Used $",
            printf ("%10s", "Diff $") AS "Diff $"
    ),
    data AS (
        SELECT
            1 AS sort_order,
            printf ("%-8d", u.id) AS "UserID",
            printf ("%-12s", u.username) AS "Username",
            printf ("%8d", COUNT(*)) AS "Queries",
            printf ("%12d", u.quota) AS "Total Quota",
            printf (
                "%12d",
                SUM(
                    CEIL(
                        l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                    )
                )
            ) AS "Calc Quota",
            printf ("%12d", u.used_quota) AS "Used Quota",
            printf (
                "%12d",
                u.used_quota - SUM(
                    CEIL(
                        l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                    )
                )
            ) AS "Diff",
            /* 计算价格: 先根据通过logs计算的quota计算原始价格，再按最小计量0.000002向上取整 */
            printf (
                "%10.6f",
                CEIL((u.quota * 0.002 / 1000) / 0.000002) * 0.000002
            ) AS "Total $",
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
                CEIL((u.used_quota * 0.002 / 1000) / 0.000002) * 0.000002
            ) AS "Used $",
            printf (
                "%10.6f",
                CEIL((u.used_quota * 0.002 / 1000) / 0.000002) * 0.000002 - CEIL(
                    (
                        SUM(
                            CEIL(
                                l.prompt_tokens * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
                            )
                        ) * 0.002 / 1000
                    ) / 0.000002
                ) * 0.000002
            ) AS "Diff $"
        FROM
            logs l
            JOIN prices p ON l.model_name = p.model
            JOIN users u ON l.user_id = u.id
        GROUP BY
            u.id,
            u.username,
            u.used_quota
    )
SELECT
    "UserID",
    "Username",
    "Queries",
    "Total Quota",
    "Calc Quota",
    "Used Quota",
    "Diff",
    "Total $",
    "Calc $",
    "Used $",
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
