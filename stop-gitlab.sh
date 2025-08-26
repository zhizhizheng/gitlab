#!/bin/bash

# GitLab 停止脚本
# 按正确顺序停止服务

echo "�� 开始停止GitLab服务..."

# 停止GitLab
echo "🐳 停止GitLab..."
docker-compose stop gitlab

# 等待GitLab完全停止
echo "⏳ 等待GitLab完全停止..."
sleep 10

# 停止PostgreSQL
echo "🐘 停止PostgreSQL..."
docker-compose stop postgresql

# 停止Redis
echo "�� 停止Redis..."
docker-compose stop redis

echo "✅ 所有服务已停止"
echo ""
echo "📋 常用命令："
echo "  完全停止并删除容器: docker-compose down"
echo "  查看容器状态: docker-compose ps"
echo "  启动服务: ./start-gitlab.sh"
