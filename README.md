# MiniMax Music Agent

基于 MiniMax AI 的音乐生成 Agent，包含三个可自定义的 MusicSkills，适用于 Claude Code。

## 完整安装步骤

### Step 1：安装基础工具

```bash
# 安装 Homebrew（如果没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Node.js 和音频播放器
brew install node mpv

# 安装 MiniMax CLI
npm install -g mmx-cli
```

### Step 2：注册 MiniMax 获取 API Key

1. 打开 https://platform.minimaxi.com （国内）或 https://platform.minimax.io （海外）
2. 注册账号
3. 进入「账户管理 > API Keys」
4. 点击生成密钥，复制保存（只显示一次）
5. 免费额度：music-2.6-free 模型，每天 100 次 API 调用

### Step 3：认证

```bash
mmx auth login --api-key sk-你的key

# 验证是否成功
mmx auth status
```

### Step 4：安装 MusicSkills

```bash
npx skills add wanhuahua0108/claude_audio_share -y -g
```

### Step 5：开始作曲

1. 打开 **Claude Code**（终端输入 `claude` 或在 VS Code / Cursor 中打开）
2. **新开一个对话**（让 Skills 加载）
3. 直接用自然语言说话：

| 你说什么 | 触发哪个 Skill | 效果 |
|---------|---------------|------|
| 帮我写一首关于夏天的歌 | minimax-music-gen | 生成带人声的歌曲 |
| 生成一段 lo-fi 纯音乐 | minimax-music-gen | 生成无人声背景音乐 |
| 用爵士风格翻唱这首歌 + 附音频 | minimax-music-gen | AI 翻唱 |
| 根据我的口味生成一个歌单 | minimax-music-playlist | 分析口味 + 批量生成 5 首 |
| 让宠物给我唱首歌 | buddy-sings | AI 宠物演唱 |

4. Skill 会自动引导你确认歌词、风格、结构
5. 等待 30-120 秒生成
6. 自动播放，文件保存在 `~/Music/minimax-gen/`

> 也可以跳过以上步骤，直接运行一键脚本：`chmod +x setup.sh && ./setup.sh`

## 三个 Skills 详解

### minimax-music-gen（核心音乐生成）

生成歌曲、纯音乐、翻唱。

- **Basic 模式**：一句话描述 → 直接生成
- **Advanced 模式**：编辑歌词 → 调整 prompt → 规划结构（BPM/调性）→ 确认生成
- 生成耗时：30-120 秒
- 输出目录：`~/Music/minimax-gen/YYYYMMDD_HHMMSS_<slug>.mp3`

支持的模型：

| 模型 | 用途 | 费用 |
|------|------|------|
| music-2.6 | 文本生成音乐 | 付费（约 $0.075/首） |
| music-2.6-free | 文本生成音乐 | 免费（每天 100 次） |
| music-cover | 从参考音频翻唱 | 付费 |
| music-cover-free | 翻唱 | 免费 |

### minimax-music-playlist（歌单生成）

分析用户音乐口味，生成个性化歌单。

- 数据来源：Apple Music（自动扫描）、Spotify（导出 ZIP）、手动输入
- 最多 5 首歌**并行生成** + 同时生成专辑封面
- 输出目录：`~/Music/minimax-gen/playlists/<playlist_name>/`
- 包含口味分析：流派分布、情绪倾向、人声偏好、节奏偏好

### buddy-sings（宠物唱歌）

让 Claude Code 的 AI 宠物给你唱歌。

- 需先通过 `/buddy` 命令设置宠物
- 会根据宠物性格生成独特声线
- 歌词以第一人称（宠物唱给主人）

## Prompt 写作建议

- **用英文写 prompt 效果最好**
- 模板：`A [mood] [BPM] [genre+sub-genre] track. [Vocal description]. [Narrative/theme]. [Atmosphere]. [Key instruments].`
- BPM 参考：40-60（冥想）、60-80（抒情）、80-110（中速）、110-130（欢快）、130-160（快速）
- 歌词结构标签：`[Intro]` `[Verse]` `[Pre Chorus]` `[Chorus]` `[Bridge]` `[Outro]` `[Hook]` `[Solo]` `[Interlude]` `[Break]` `[Build Up]`
- 声音描述用人格化方式，如 "warm baritone with jazz inflections"，而非技术参数
- 指定 2-3 种主要乐器即可，其余留给 AI 自由发挥

## 自定义 Skills

Fork 本仓库，修改 `skills/` 下的 SKILL.md 文件，然后从你自己的 fork 安装：

```bash
npx skills add your-username/claude_audio_share -y -g
```

你可以自定义：

- 默认音乐风格和 prompt 模板
- 歌词语言偏好
- 输出目录和文件命名规则
- 歌单生成逻辑和口味分析权重

## 仓库结构

```text
claude_audio_share/
├── README.md
├── setup.sh                                  # 一键搭建脚本
└── skills/                                   # 三个 MusicSkills（可自定义）
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
