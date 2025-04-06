-- update_quota.sql
-- 本文件用于更新logs表中的quota字段，采用公式： 
-- quota = CEIL(prompt_tokens * JSON_EXTRACT(metadata, '$.input_ratio') + completion_tokens * JSON_EXTRACT(metadata, '$.output_ratio'))
UPDATE logs
SET
    quota = CEIL(
        (
            prompt_tokens * JSON_EXTRACT (metadata, '$.input_ratio') + completion_tokens * JSON_EXTRACT (metadata, '$.output_ratio')
        ) * COALESCE(
            (
                SELECT
                    ratio
                FROM
                    user_groups
                WHERE
                    user_groups.symbol = token_name
            ),
            1
        )
    );