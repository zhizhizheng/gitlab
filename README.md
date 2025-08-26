# GitLab 私有化部署配置（32G内存 + 2T SSD优化）

## 配置说明

本配置针对以下需求进行了优化：
- **硬件配置**：i5处理器、32G内存、2T SSD
- **性能要求不高**：一致性、易维护性高于性能要求
- **数据状态强一致**：确保PostgreSQL数据完整性
- **允许断电时操作丢失**：Redis配置为内存模式
- **宿主机重启后继续服务**：所有数据持久化到宿主机
- **Redis缓存无需落地**：配置为纯内存模式
- **PostgreSQL数据状态强一致**：启用同步提交和WAL日志

## 启动顺序保证

### 健康检查机制

为确保PostgreSQL完全启动后再启动GitLab，配置了以下机制：

1. **PostgreSQL健康检查**：
   ```yaml
   healthcheck:
     test: ["CMD-SHELL", "pg_isready -U gitlab -d gitlabhq_production"]
     interval: 10s
     timeout: 5s
     retries: 5
     start_period: 30s
   ```

2. **Redis健康检查**：
   ```yaml
   healthcheck:
     test: ["CMD", "redis-cli", "ping"]
     interval: 10s
     timeout: 3s
     retries: 5
     start_period: 10s
   ```

3. **GitLab启动依赖**：
   ```yaml
   depends_on:
     postgresql:
       condition: service_healthy
     redis:
       condition: service_healthy
   ```

### 启动脚本

提供了智能启动脚本 `start-gitlab.sh`：

```bash
# 给脚本执行权限
chmod +x start-gitlab.sh

# 启动服务
./start-gitlab.sh
```

启动脚本会：
1. 按顺序启动PostgreSQL和Redis
2. 等待服务完全启动并健康检查通过
3. 启动GitLab
4. 监控启动状态并提供反馈

## 硬件资源分配

### 内存分配（32G）
- **PostgreSQL共享缓冲区**：8GB
- **PostgreSQL有效缓存**：24GB
- **Redis缓存**：4GB
- **GitLab Unicorn进程**：8个worker（每个256-512MB）
- **系统预留**：约4GB

### SSD存储分配（2T）
- **GitLab数据**：约1.5T（代码仓库、用户数据等）
- **PostgreSQL数据**：约300GB
- **日志文件**：约100GB
- **配置文件**：约100GB

## 主要优化

### 1. PostgreSQL 强一致性配置

- **同步提交**：`synchronous_commit = on` - 确保事务在返回成功前已写入磁盘
- **fsync**：`fsync = on` - 强制将数据写入物理磁盘
- **完整页面写入**：`full_page_writes = on` - 确保崩溃恢复时数据完整性
- **WAL日志提示**：`wal_log_hints = on` - 提高崩溃恢复可靠性
- **数据校验**：`--data-checksums` - 启用数据校验和检测
- **内存优化**：`shared_buffers = 8GB` - 充分利用32G内存
- **WAL优化**：`wal_keep_size = 4GB` - 充分利用SSD存储

### 2. Redis 内存配置

- **禁用持久化**：`--save "" --appendonly no` - 不保存数据到磁盘
- **内存限制**：`--maxmemory 4gb` - 充分利用可用内存
- **LRU策略**：`--maxmemory-policy allkeys-lru` - 内存不足时删除最近最少使用的键
- **连接保活**：`--tcp-keepalive 300` - 提高连接稳定性

### 3. GitLab 性能优化

- **Unicorn进程**：8个worker进程（充分利用多核CPU）
- **超时设置**：120秒worker超时
- **内存限制**：每个worker 256-512MB
- **PostgreSQL参数**：优化内存和I/O配置

### 4. 日志和监控

- **PostgreSQL日志**：详细记录所有操作，便于问题排查
- **性能监控**：启用pg_stat_statements和pg_stat_monitor
- **连接监控**：记录所有连接和断开
- **锁等待监控**：记录锁等待情况

## 部署步骤

### 方法一：使用启动脚本（推荐）

1. 给脚本执行权限：
```bash
chmod +x start-gitlab.sh stop-gitlab.sh
```

2. 启动服务：
```bash
./start-gitlab.sh
```

3. 停止服务：
```bash
./stop-gitlab.sh
```

### 方法二：使用docker-compose

1. 创建必要的目录：
```bash
mkdir -p gitlab/{config,logs,data}
mkdir -p postgresql/{data,logs}
```

2. 启动所有服务：
```bash
docker-compose up -d
```

3. 查看日志：
```bash
docker-compose logs -f gitlab
```

## 数据持久化

- **GitLab数据**：`./gitlab/data` - 代码仓库、用户数据等
- **GitLab配置**：`./gitlab/config` - GitLab配置文件
- **GitLab日志**：`./gitlab/logs` - 应用日志
- **PostgreSQL数据**：`./postgresql/data` - 数据库文件
- **PostgreSQL日志**：`./postgresql/logs` - 数据库日志

## 性能监控

### 容器资源监控
```bash
# 查看容器资源使用情况
docker stats

# 查看容器状态
docker-compose ps
```

### PostgreSQL性能监控
```sql
-- 查看慢查询
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- 查看缓存命中率
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit)  as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read))::float as ratio
FROM pg_statio_user_tables;
```

### GitLab性能监控
```bash
# 查看GitLab进程状态
docker exec gitlab gitlab-ctl status

# 查看GitLab日志
docker exec gitlab tail -f /var/log/gitlab/gitlab-rails/production.log
```

## 注意事项

1. **首次启动**：GitLab首次启动需要较长时间进行初始化（约10-15分钟）
2. **数据备份**：定期备份 `./gitlab/data` 和 `./postgresql/data` 目录
3. **断电恢复**：系统重启后会自动恢复，但Redis缓存会丢失
4. **性能监控**：可通过 `docker stats` 监控容器资源使用情况
5. **日志管理**：PostgreSQL日志会自动轮转，避免占用过多磁盘空间
6. **启动顺序**：使用启动脚本确保正确的启动顺序

## 故障排除

### 常见问题

1. **GitLab无法访问**：
   - 检查容器状态：`docker-compose ps`
   - 查看日志：`docker-compose logs gitlab`
   - 检查端口占用：`netstat -tlnp | grep :80`

2. **数据库连接失败**：
   - 检查PostgreSQL容器状态
   - 验证网络连接：`docker network ls`
   - 查看数据库日志：`docker-compose logs postgresql`

3. **启动顺序问题**：
   - 使用启动脚本：`./start-gitlab.sh`
   - 检查健康状态：`docker-compose ps`
   - 查看健康检查日志：`docker inspect gitlab_postgresql`

4. **内存不足**：
   - 监控内存使用：`free -h`
   - 调整Redis内存限制
   - 减少Unicorn worker数量

5. **磁盘空间不足**：
   - 检查磁盘使用：`df -h`
   - 清理日志文件
   - 清理Docker镜像：`docker system prune`

### 日志位置

- GitLab应用日志：`./gitlab/logs/`
- PostgreSQL日志：`./postgresql/logs/`
- Redis日志：`docker-compose logs redis`
- Docker日志：`docker-compose logs`

### 性能调优建议

1. **内存优化**：
   - 监控内存使用情况
   - 根据实际使用调整shared_buffers
   - 调整Redis内存限制

2. **磁盘优化**：
   - 定期清理日志文件
   - 监控磁盘I/O性能
   - 考虑使用SSD优化参数

3. **网络优化**：
   - 监控网络连接数
   - 调整TCP连接参数
   - 优化Nginx配置
