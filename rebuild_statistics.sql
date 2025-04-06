INSERT
OR REPLACE INTO statistics (
    date,
    user_id,
    channel_id,
    model_name,
    request_count,
    quota,
    prompt_tokens,
    completion_tokens,
    request_time
)
SELECT
    strftime (
        '%Y-%m-%d',
        datetime (created_at, 'unixepoch', '+8 hours')
    ) as date,
    user_id,
    channel_id,
    model_name,
    count(1) as request_count,
    sum(
        quota * COALESCE(
            (
                SELECT
                    ratio
                FROM
                    user_groups
                WHERE
                    user_groups.symbol = logs.token_name
            ),
            1
        )
    ) as quota,
    sum(prompt_tokens) as prompt_tokens,
    sum(completion_tokens) as completion_tokens,
    sum(request_time) as request_time
FROM
    logs
WHERE
    type = 2
GROUP BY
    date,
    channel_id,
    user_id,
    model_name
ORDER BY
    date,
    model_name;