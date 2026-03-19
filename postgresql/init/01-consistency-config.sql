-- PostgreSQL 强一致性配置（32G内存 + 2T SSD优化）
-- 确保数据完整性和一致性，充分利用硬件资源

-- 设置事务隔离级别为可串行化（最高级别）
ALTER SYSTEM SET default_transaction_isolation = 'serializable';

-- 确保同步提交
ALTER SYSTEM SET synchronous_commit = on;

-- 启用fsync确保数据写入磁盘
ALTER SYSTEM SET fsync = on;

-- 启用完整页面写入
ALTER SYSTEM SET full_page_writes = on;

-- 启用WAL日志提示
ALTER SYSTEM SET wal_log_hints = on;

-- 设置WAL保留大小（充分利用SSD）
ALTER SYSTEM SET wal_keep_size = '4GB';

-- 设置最大WAL大小
ALTER SYSTEM SET max_wal_size = '4GB';

-- 设置最小WAL大小
ALTER SYSTEM SET min_wal_size = '1GB';

-- 设置检查点完成目标
ALTER SYSTEM SET checkpoint_completion_target = 0.9;

-- 设置WAL缓冲区（充分利用内存）
ALTER SYSTEM SET wal_buffers = '64MB';

-- 设置共享缓冲区（充分利用32G内存）
ALTER SYSTEM SET shared_buffers = '8GB';

-- 设置有效缓存大小（充分利用内存）
ALTER SYSTEM SET effective_cache_size = '24GB';

-- 设置工作内存（充分利用内存）
ALTER SYSTEM SET work_mem = '32MB';

-- 设置维护工作内存（充分利用内存）
ALTER SYSTEM SET maintenance_work_mem = '1GB';

-- 设置默认统计目标（提高查询优化）
ALTER SYSTEM SET default_statistics_target = 500;

-- 设置随机页面成本（SSD优化）
ALTER SYSTEM SET random_page_cost = 1.1;

-- 设置有效IO并发（SSD优化）
ALTER SYSTEM SET effective_io_concurrency = 400;

-- 日志配置（充分利用SSD）
ALTER SYSTEM SET log_destination = 'stderr';
ALTER SYSTEM SET logging_collector = 'on';
ALTER SYSTEM SET log_directory = 'log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';
ALTER SYSTEM SET log_rotation_age = '1d';
ALTER SYSTEM SET log_rotation_size = '100MB';
ALTER SYSTEM SET log_min_duration_statement = '1000';
ALTER SYSTEM SET log_checkpoints = 'on';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_lock_waits = 'on';
ALTER SYSTEM SET log_temp_files = '0';
ALTER SYSTEM SET log_autovacuum_min_duration = '0';
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';

-- 重新加载配置
SELECT pg_reload_conf();

-- 创建用于监控的扩展
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 创建用于性能分析的扩展
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_available_extensions
        WHERE name = 'pg_stat_monitor'
    ) THEN
        CREATE EXTENSION IF NOT EXISTS pg_stat_monitor;
    ELSE
        RAISE NOTICE 'pg_stat_monitor is not available in this PostgreSQL image, skip installation.';
    END IF;
END
$$;

-- 设置统计收集
ALTER SYSTEM SET track_activities = 'on';
ALTER SYSTEM SET track_counts = 'on';
ALTER SYSTEM SET track_io_timing = 'on';
ALTER SYSTEM SET track_functions = 'all';

-- 重新加载配置
SELECT pg_reload_conf();
