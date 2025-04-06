-- 根据logs表中的token消耗更新users表的used_quota字段
UPDATE users u
SET used_quota = subquery.calculated_quota
FROM (
    SELECT 
        l.user_id,
        SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input * c.weight)
                ELSE CEIL(
                    (l.prompt_tokens * (p.input * c.weight)) + 
                    (l.completion_tokens * (p.output * c.weight))
                )
            END
        ) AS calculated_quota
    FROM 
        logs l
    JOIN 
        prices p ON l.model_name = p.model
    JOIN
        channels c ON l.channel_id = c.id
    GROUP BY 
        l.user_id
) AS subquery
WHERE u.id = subquery.user_id;

-- 记录quota更新日志
INSERT INTO quota_updates (user_id, old_quota, new_quota, updated_at)
SELECT 
    u.id,
    u.used_quota AS old_quota,
    subquery.calculated_quota AS new_quota,
    NOW() AS updated_at
FROM users u
JOIN (
    SELECT 
        l.user_id,
        SUM(
            CASE 
                WHEN p.type = 'times' THEN 1000 * (p.input * c.weight)
                ELSE CEIL(
                    (l.prompt_tokens * (p.input * c.weight)) + 
                    (l.completion_tokens * (p.output * c.weight))
                )
            END
        ) AS calculated_quota
    FROM 
        logs l
    JOIN 
        prices p ON l.model_name = p.model
    JOIN
        channels c ON l.channel_id = c.id
    GROUP BY 
        l.user_id
) AS subquery ON u.id = subquery.user_id;
