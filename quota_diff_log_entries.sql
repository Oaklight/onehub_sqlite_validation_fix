-- Extract individual log entries with quota differences
-- This query retrieves detailed log entries where the calculated quota and logged quota differ
SELECT
    l.user_id AS "UserID",
    u.username AS "Username",
    l.id AS "LogID",
    l.prompt_tokens AS "Prompt Tokens",
    l.completion_tokens AS "Completion Tokens",
    JSON_EXTRACT (l.metadata, '$.input_ratio') AS "Input Ratio",
    JSON_EXTRACT (l.metadata, '$.output_ratio') AS "Output Ratio",
    JSON_EXTRACT (l.metadata, '$.cached_tokens') AS "Cached Tokens",
    JSON_EXTRACT (l.metadata, '$.cached_tokens_ratio') AS "Cached Tokens Ratio",
    l.quota AS "Log Quota",
    l.created_at AS "Created At",
    l.type AS "Type",
    l.content AS "Content",
    l.token_name AS "Token Name",
    l.model_name AS "Model Name",
    l.channel_id AS "Channel ID",
    l.request_time AS "Request Time",
    l.is_stream AS "Is Stream",
    l.metadata AS "Metadata",
    CEIL(
        (
            (
                l.prompt_tokens + (
                    COALESCE(JSON_EXTRACT (l.metadata, '$.cached_tokens'), 0) * COALESCE(
                        JSON_EXTRACT (l.metadata, '$.cached_tokens_ratio'),
                        0
                    )
                )
            ) * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
        ) * COALESCE(
            (
                SELECT
                    ratio
                FROM
                    user_groups
                WHERE
                    user_groups.symbol = l.token_name
            ),
            1
        )
    ) AS "Calc Quota",
    CEIL(
        (
            (
                l.prompt_tokens + (
                    COALESCE(JSON_EXTRACT (l.metadata, '$.cached_tokens'), 0) * COALESCE(
                        JSON_EXTRACT (l.metadata, '$.cached_tokens_ratio'),
                        0
                    )
                )
            ) * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
        ) * COALESCE(
            (
                SELECT
                    ratio
                FROM
                    user_groups
                WHERE
                    user_groups.symbol = l.token_name
            ),
            1
        )
    ) - l.quota AS "Diff"
FROM
    logs l
    JOIN users u ON l.user_id = u.id
WHERE
    CEIL(
        (
            (
                l.prompt_tokens + (
                    COALESCE(JSON_EXTRACT (l.metadata, '$.cached_tokens'), 0) * COALESCE(
                        JSON_EXTRACT (l.metadata, '$.cached_tokens_ratio'),
                        0
                    )
                )
            ) * JSON_EXTRACT (l.metadata, '$.input_ratio') + l.completion_tokens * JSON_EXTRACT (l.metadata, '$.output_ratio')
        ) * COALESCE(
            (
                SELECT
                    ratio
                FROM
                    user_groups
                WHERE
                    user_groups.symbol = l.token_name
            ),
            1
        )
    ) != l.quota
ORDER BY
    l.user_id ASC,
    l.id ASC;
