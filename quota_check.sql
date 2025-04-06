-- 计算每个用户的实际quota消耗与used_quota的差异
-- 使用token消耗和prices表定价计算真实quota
SELECT 
    l.user_id,
    l.username,
    SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1) -- 按次计费公式
            ELSE CEIL(
                (l.prompt_tokens * (p.input * 1)) + 
                (l.completion_tokens * (p.output * 1)) -- 按token计费公式
            )
        END
    ) AS calculated_quota,
    u.used_quota AS current_used_quota,
    SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1)
            ELSE CEIL(
                (l.prompt_tokens * (p.input * 1)) + 
                (l.completion_tokens * (p.output * 1))
            )
        END
    ) - u.used_quota AS quota_diff
FROM 
    logs l
JOIN 
    prices p ON l.model_name = p.model
JOIN
    users u ON l.user_id = u.id
GROUP BY 
    l.user_id, u.username, u.used_quota
ORDER BY 
    l.user_id DESC;
