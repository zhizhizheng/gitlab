#!/bin/bash

# GitLab 启动脚本
# 确保PostgreSQL和Redis完全启动后再启动GitLab

set -e

echo "🐳 开始启动GitLab服务..."

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p gitlab/{config,logs,data}
mkdir -p postgresql/{data,logs}

# 启动PostgreSQL和Redis
echo "🐘 启动PostgreSQL..."
docker compose up -d postgresql

echo "🔥 启动Redis..."
docker compose up -d redis

# 等待PostgreSQL完全启动
echo "⏳ 等待PostgreSQL完全启动..."
until docker compose exec -T postgresql pg_isready -U gitlab -d gitlabhq_production; do
    echo "PostgreSQL还在启动中，等待10秒..."
    sleep 10
done
echo "✅ PostgreSQL已完全启动并准备接受连接"

# 等待Redis完全启动
echo "⏳ 等待Redis完全启动..."
until docker compose exec -T redis redis-cli ping; do
    echo "Redis还在启动中，等待5秒..."
    sleep 5
done
echo "✅ Redis已完全启动并准备接受连接"

# 检查PostgreSQL健康状态
echo "🔍 检查PostgreSQL健康状态..."
for i in {1..30}; do
    if docker compose exec -T postgresql pg_isready -U gitlab -d gitlabhq_production > /dev/null 2>&1; then
        echo "✅ PostgreSQL健康检查通过"
        break
    else
        echo "PostgreSQL健康检查失败，重试 $i/30..."
        sleep 10
    fi
done

# 检查Redis健康状态
echo "🔍 检查Redis健康状态..."
for i in {1..30}; do
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis健康检查通过"
        break
    else
        echo "Redis健康检查失败，重试 $i/30..."
        sleep 5
    fi
done

# 启动GitLab
echo "🐳 启动GitLab..."
docker compose up -d gitlab

echo "⏳ 等待GitLab启动..."
echo "GitLab首次启动需要较长时间（约10-15分钟），请耐心等待..."

# 监控GitLab启动状态
echo "📊 监控GitLab启动状态..."
for i in {1..60}; do
    if docker compose exec -T gitlab gitlab-ctl status > /dev/null 2>&1; then
        echo "✅ GitLab已成功启动！"
        echo "🌐 访问地址: https://gitlab.feifan-game.com"
        echo "📝 查看日志: docker compose logs -f gitlab"
        break
    else
        echo "GitLab还在启动中，等待30秒... ($i/60)"
        sleep 30
    fi
done

echo "🎉 GitLab服务启动完成！"
echo ""
echo "📋 常用命令："
echo "  查看状态: docker compose ps"
echo "  查看日志: docker compose logs -f gitlab"
echo "  停止服务: docker compose down"
echo "  重启服务: docker compose restart"
echo ""
echo "🔧 故障排除："
echo "  如果GitLab无法访问，请检查："
echo "  1. 容器状态: docker compose ps"
echo "  2. 端口占用: netstat -tlnp | grep :80"
echo "  3. 网络连接: docker network ls"