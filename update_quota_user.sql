-- update_quota_user.sql
-- 本文件用于调整users表中的used_quota字段，并对users表中的quota字段进行多退少补。
-- 多退少补逻辑：
-- 直接查询logs表中对应用户的quota总和，新值记为new_used，
-- 则将users表中的quota调整为：quota = quota + (旧 used_quota - new_used)
-- 同时将used_quota更新为new_used。
UPDATE users
SET
    quota = quota + (
        used_quota - (
            SELECT
                COALESCE(
                    SUM(
                        CEIL(
                            prompt_tokens * COALESCE(JSON_EXTRACT (metadata, '$.input_ratio'), 1.0) + completion_tokens * COALESCE(JSON_EXTRACT (metadata, '$.output_ratio'), 1.0)
                        )
                    ),
                    0
                )
            FROM
                logs l
                LEFT JOIN prices p ON l.model_name = p.model
            WHERE
                p.model IS NOT NULL
                AND l.user_id = users.id
        )
    ),
    used_quota = (
        SELECT
            COALESCE(
                SUM(
                    CEIL(
                        prompt_tokens * COALESCE(JSON_EXTRACT (metadata, '$.input_ratio'), 1.0) + completion_tokens * COALESCE(JSON_EXTRACT (metadata, '$.output_ratio'), 1.0)
                    )
                ),
                0
            )
        FROM
            logs l
            LEFT JOIN prices p ON l.model_name = p.model
        WHERE
            p.model IS NOT NULL
            AND l.user_id = users.id
    );
