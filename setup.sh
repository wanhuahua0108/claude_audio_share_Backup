#!/bin/bash
# MiniMax 音乐 Agent 一键搭建脚本
# 使用方法：chmod +x setup.sh && ./setup.sh

set -e

echo "=== MiniMax 音乐 Agent 搭建 ==="
echo ""

# 检查 Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ 未安装 Homebrew，请先安装：https://brew.sh"
    exit 1
fi

# 安装 Node.js
if ! command -v node &> /dev/null; then
    echo "📦 安装 Node.js..."
    brew install node
else
    echo "✅ Node.js 已安装：$(node --version)"
fi

# 安装 mpv
if ! command -v mpv &> /dev/null; then
    echo "📦 安装 mpv 播放器..."
    brew install mpv
else
    echo "✅ mpv 已安装"
fi

# 安装 mmx-cli
if ! command -v mmx &> /dev/null; then
    echo "📦 安装 mmx-cli..."
    npm install -g mmx-cli
else
    echo "✅ mmx-cli 已安装"
fi

# 认证
echo ""
echo "🔑 MiniMax API 认证"
echo "  国内注册：https://platform.minimaxi.com"
echo "  海外注册：https://platform.minimax.io"
echo ""
read -p "请输入你的 API Key (sk-xxx): " API_KEY

if [ -z "$API_KEY" ]; then
    echo "❌ API Key 不能为空"
    exit 1
fi

mmx auth login --api-key "$API_KEY"
echo ""
mmx auth status

# 安装 MusicSkills
echo ""
echo "📦 安装三个 MusicSkills..."
npx skills add MiniMax-AI/skills --skill minimax-music-gen minimax-music-playlist buddy-sings --agent claude-code -y -g

# 创建输出目录
mkdir -p ~/Music/minimax-gen

# 测试
echo ""
echo "🎵 测试生成一首纯音乐..."
mmx music generate --prompt "A calm lo-fi chill hop track, 80 BPM" --instrumental --out ~/Music/minimax-gen/setup_test.mp3 --quiet --non-interactive

if [ -f ~/Music/minimax-gen/setup_test.mp3 ]; then
    echo ""
    echo "✅ 搭建完成！测试音乐已保存到 ~/Music/minimax-gen/setup_test.mp3"
    echo ""
    echo "使用方式："
    echo "  在 Claude Code 中说「帮我写一首歌」→ 触发 minimax-music-gen"
    echo "  在 Claude Code 中说「生成一个歌单」→ 触发 minimax-music-playlist"
    echo "  在 Claude Code 中说「让宠物唱首歌」→ 触发 buddy-sings"
else
    echo "❌ 测试生成失败，请检查 API Key 和网络"
    exit 1
fi
