# OneHub SQLite 数据库消费分析纠错

## 背景

这些脚本是用来分析 OneHub 的 SQLite 部署版本的消费统计数据。请确保你的 OneHub 数据库已经做过备份，不要直接在不清楚风险的情况下运行下列脚本。

## 注意事项

- 确保`test.db`位于当前工作目录中或提供完整路径。
- 脚本设计与现有数据库架构兼容，若数据库架构发生修改，可能需要更新脚本。

## 脚本文档

此文件夹包含用于管理和分析 SQLite 数据库（`test.db`）的各种 SQL 脚本。以下是每个脚本的说明以及如何结合 SQLite 使用的指南。

### 1. `quota_check_log.sql`

- **用途**：比较`logs`表中的计算配额和记录配额，突出差异并计算相关费用。
- **使用方法**：运行脚本以生成配额差异和价格差异的报告。
- **命令**：`sqlite3 test.db < sqls/quota_check_log.sql`

### 2. `quota_check_user.sql`

- **用途**：生成用户配额的摘要，包括总配额、计算配额、使用配额及相关费用。
- **使用方法**：运行脚本以查看每个用户的配额详情。
- **命令**：`sqlite3 test.db < sqls/quota_check_user.sql`

### 3. `update_quota_log.sql`

- **用途**：根据新计算更新`logs`表中的配额信息。
- **使用方法**：**注意**：此脚本会直接修改`logs`表的配额数据，除非完全理解其影响，否则不要使用。
- **命令**：`sqlite3 test.db < sqls/update_quota_log.sql`

### 4. `update_quota_user.sql`

- **用途**：根据新计算更新`users`表中的用户配额信息。
- **使用方法**：**注意**：此脚本会直接修改`users`表的配额数据，除非完全理解其影响，否则不要使用。
- **命令**：`sqlite3 test.db < sqls/update_quota_user.sql`

## 如何结合 SQLite 使用这些脚本

1. 打开终端并导航到包含`test.db`的项目目录。
2. 使用`sqlite3`命令执行任意脚本：

   ```
   sqlite3 test.db < path/to/script.sql
   ```

   将`path/to/script.sql`替换为您要运行的脚本的实际路径（例如：`sqls/quota_check_log.sql`）。

3. 在终端中查看输出或检查数据库中的更新数据。

## 背景与注意事项

### 背景

这些脚本是用来分析 OneHub 的 SQLite 部署版本的消费统计数据。请确保你的 OneHub 数据库已经做过备份，不要直接在不清楚风险的情况下运行下列脚本。

### 注意事项

- 确保`test.db`位于当前工作目录中或提供完整路径。
- 脚本设计与现有数据库架构兼容，若数据库架构发生修改，可能需要更新脚本。
