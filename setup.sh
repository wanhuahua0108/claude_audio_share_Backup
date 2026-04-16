#!/bin/bash
# AI 音乐 Agent 一键搭建脚本（MiniMax + Suno）
# 使用方法：chmod +x setup.sh && ./setup.sh

set -e

echo "=== AI 音乐 Agent 搭建（MiniMax + Suno）==="
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

# Suno API（可选）
echo ""
echo "🎵 Suno API 配置（可选，按回车跳过）"
echo "  注册：https://sunoapi.org"
echo ""
read -p "请输入 Suno API Key（留空跳过）: " SUNO_KEY

if [ -n "$SUNO_KEY" ]; then
    mkdir -p ~/.suno
    echo "{\"api_key\":\"$SUNO_KEY\"}" > ~/.suno/config.json
    echo "✅ Suno API Key 已保存到 ~/.suno/config.json"

    # 验证 Suno API Key
    SUNO_CREDIT=$(curl -s -H "Authorization: Bearer $SUNO_KEY" \
      "https://api.sunoapi.org/api/v1/generate/credit" 2>/dev/null | jq -r '.data.remainingCredits // empty' 2>/dev/null)
    if [ -n "$SUNO_CREDIT" ]; then
        echo "✅ Suno 剩余额度：$SUNO_CREDIT"
    else
        echo "⚠️  无法验证 Suno API Key，请稍后手动检查"
    fi
else
    echo "⏭️  跳过 Suno 配置（之后可手动设置）"
fi

# 安装 MusicSkills
echo ""
echo "📦 安装四个 MusicSkills..."
npx skills add MiniMax-AI/skills --skill minimax-music-gen minimax-music-playlist buddy-sings --agent claude-code -y -g

# 创建输出目录
mkdir -p ~/Music/minimax-gen ~/Music/suno-gen

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
    echo "  在 Claude Code 中说「用Suno写首歌」→ 触发 suno-music-gen"
    echo "  在 Claude Code 中说「生成一个歌单」→ 触发 minimax-music-playlist"
    echo "  在 Claude Code 中说「让宠物唱首歌」→ 触发 buddy-sings"
else
    echo "❌ 测试生成失败，请检查 API Key 和网络"
    exit 1
fi
