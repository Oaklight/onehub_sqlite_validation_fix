-- 计算每个用户的实际quota使用情况（合并同一 userid 的多条记录）
-- 假设条件:
-- 1. 音频输入/输出 token 为 0 (表中无此字段)
-- 2. 缓存 token 为 0 (表中无此字段) 
-- 3. 分组倍率为 1 (需要从 users 表获取实际值)
-- 价格计算公式: quota * 0.002 / 1000 = price

SELECT 
    l.user_id,
    MIN(l.username) AS username, -- 合并记录时保留其中一个用户名
    SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1) -- 按次计费公式
            ELSE CEIL(l.prompt_tokens * (p.input * 1) + l.completion_tokens * (p.output * 1)) -- 按 token 计费公式
        END
    ) AS calculated_quota,
    SUM(l.quota) AS actual_quota,
    SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1)
            ELSE CEIL(l.prompt_tokens * (p.input * 1) + l.completion_tokens * (p.output * 1))
        END
    ) - SUM(l.quota) AS quota_diff,
    SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1)
            ELSE CEIL(l.prompt_tokens * (p.input * 1) + l.completion_tokens * (p.output * 1))
        END
    ) * 0.002/1000 AS calculated_prices,
    SUM(l.quota) * 0.002/1000 AS actual_prices,
    (SUM(
        CASE 
            WHEN p.type = 'times' THEN 1000 * (p.input * 1)
            ELSE CEIL(l.prompt_tokens * (p.input * 1) + l.completion_tokens * (p.output * 1))
        END
    ) * 0.002/1000) - (SUM(l.quota) * 0.002/1000) AS prices_diff
FROM 
    logs l
JOIN 
    prices p ON l.model_name = p.model
GROUP BY 
    l.user_id
ORDER BY 
    l.user_id DESC;
