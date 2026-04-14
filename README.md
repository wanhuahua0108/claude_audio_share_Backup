# MiniMax Music Agent

基于 MiniMax AI 的音乐生成 Agent，包含三个可自定义的 MusicSkills，适用于 Claude Code。

## 一行命令安装

```bash
npx skills add wanhuahua0108/claude_audio_share -y -g
```

## 前置条件

```bash
# 安装依赖
brew install node mpv
npm install -g mmx-cli

# 注册 MiniMax 并获取 API Key
#   国内：https://platform.minimaxi.com
#   海外：https://platform.minimax.io

# 认证
mmx auth login --api-key sk-你的key
```

或者直接运行一键脚本：

```bash
chmod +x setup.sh && ./setup.sh
```

## 三个 Skills

### minimax-music-gen
核心音乐生成。支持歌曲、纯音乐、翻唱。

- Basic 模式：一句话描述 → 直接生成
- Advanced 模式：编辑歌词 → 调整 prompt → 规划结构 → 确认生成
- 输出：`~/Music/minimax-gen/`

### minimax-music-playlist
个性化歌单生成。分析你的音乐口味，批量生成歌单。

- 数据来源：Apple Music、Spotify、手动输入
- 最多 5 首歌并行生成 + 专辑封面
- 输出：`~/Music/minimax-gen/playlists/`

### buddy-sings
让 Claude Code 的 AI 宠物给你唱歌。

- 需先通过 `/buddy` 设置宠物

## 使用方式

安装完成后，新开一个 Claude Code 对话，直接说：

- 「帮我写一首歌」→ 触发 minimax-music-gen
- 「根据我的口味生成一个歌单」→ 触发 minimax-music-playlist
- 「让宠物给我唱首歌」→ 触发 buddy-sings

## 自定义

Fork 本仓库，修改 `skills/` 下的 SKILL.md 文件，然后从你自己的 fork 安装：

```bash
npx skills add your-username/claude_audio_share -y -g
```

你可以自定义：
- 默认音乐风格和 prompt 模板
- 歌词语言偏好
- 输出目录和文件命名规则
- 歌单生成逻辑和口味分析权重

## Prompt 写作建议

- **用英文写 prompt 效果最好**
- 模板：`A [mood] [BPM] [genre+sub-genre] track. [Vocal description]. [Narrative/theme]. [Atmosphere]. [Key instruments].`
- BPM 参考：40-60（冥想）、60-80（抒情）、80-110（中速）、110-130（欢快）、130-160（快速）
- 歌词结构标签：`[Intro]` `[Verse]` `[Chorus]` `[Bridge]` `[Outro]` `[Hook]` `[Solo]` 等

## 仓库结构

```text
claude_audio_share/
├── README.md
├── setup.sh                                  # 一键搭建脚本
└── skills/                                   # 三个 MusicSkills
    ├── minimax-music-gen/
    │   ├── SKILL.md                          # 核心音乐生成指令
    │   └── references/prompt_guide.md        # Prompt 写作指南
    ├── minimax-music-playlist/
    │   ├── SKILL.md                          # 歌单生成指令
    │   └── data/artist_genre_map.json        # 20000+ 艺术家流派映射
    └── buddy-sings/
        └── SKILL.md                          # 宠物唱歌指令
```

## 致谢

- Skills 基于 [MiniMax-AI/skills](https://github.com/MiniMax-AI/skills) (MIT License)
- 音乐生成使用 [MiniMax Music 2.6](https://www.minimax.io) 模型
