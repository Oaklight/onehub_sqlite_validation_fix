-- update_users_quota_and_balance.sql
-- 本文件用于重写users表中的used_quota，并根据400 USD对应的quota更新users表中的quota余额。
-- 1. 更新used_quota字段：从logs表汇总每个用户的quota总和（需先确保logs表中的quota已更新）。
-- 2. 计算400 USD对应的quota：由于price = quota * 0.002 / 1000，
--    故quota = price * (1000 / 0.002) = price * 500000，
--    当price为400 USD时，对应quota = 400 * 500000 = 200000000。
-- 3. 更新users表中的quota余额为：quota = 200000000 - used_quota。
BEGIN TRANSACTION;

-- 更新used_quota字段：直接从logs表汇总已更新的quota值
UPDATE users
SET
    used_quota = (
        SELECT
            COALESCE(SUM(quota), 0)
        FROM
            logs
        WHERE
            logs.user_id = users.id
    );

-- 更新quota余额字段，根据400 USD对应的quota上限
UPDATE users
SET
    quota = 200000000 - used_quota;

COMMIT;