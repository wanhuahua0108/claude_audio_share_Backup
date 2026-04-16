# Windows 跨平台适配指南

> 四个 MusicSkills（MiniMax + Suno）在 Windows 上的部署说明

## 兼容性总览

| Skill | Windows 兼容性 | 主要适配项 |
|-------|--------------|-----------|
| **minimax-music-gen** | 完全兼容 | 音频播放器、路径 |
| **suno-music-gen** | 完全兼容 | 需装 curl/jq、路径 |
| **minimax-music-playlist** | 部分兼容 | Apple Music 不可用，需用 Spotify 或手动输入 |
| **buddy-sings** | 完全兼容 | 音频播放器、路径 |

---

## 1. 系统依赖安装

### 必需

```powershell
# Node.js（mmx-cli 运行时）
winget install OpenJS.NodeJS.LTS

# mmx-cli（MiniMax 音乐生成）
npm install -g mmx-cli

# Git（仓库管理 + Git Bash 环境）
winget install Git.Git
```

### 推荐

```powershell
# mpv（音频播放，所有 Skill 通用）
winget install mpv.net

# jq（Suno Skill 的 JSON 解析）
winget install jqlang.jq

# curl（Windows 10+ 自带，但建议确认）
curl --version
```

### 可选

```powershell
# ffmpeg（包含 ffplay，备用播放器）
winget install Gyan.FFmpeg
```

---

## 2. 各 Skill 适配详情

### minimax-music-gen

**兼容性：完全兼容**

| macOS 写法 | Windows 适配 |
|-----------|-------------|
| `~/Music/minimax-gen/` | `%USERPROFILE%\Music\minimax-gen\` |
| `brew install mpv` | `winget install mpv.net` |
| `afplay file.mp3` | `mpv --no-video file.mp3` |
| `mkdir -p ~/Music/minimax-gen` | `mkdir "%USERPROFILE%\Music\minimax-gen"` |

`mmx-cli` 本身跨平台，Windows 上行为一致：
```powershell
mmx auth login --api-key sk-xxxxx
mmx music generate --prompt "A calm lo-fi track" --instrumental --out "%USERPROFILE%\Music\minimax-gen\test.mp3"
```

---

### suno-music-gen

**兼容性：完全兼容（需装 jq）**

| macOS 写法 | Windows 适配 |
|-----------|-------------|
| `~/Music/suno-gen/` | `%USERPROFILE%\Music\suno-gen\` |
| `brew install jq` | `winget install jqlang.jq` |
| `export SUNO_API_KEY="..."` | `set SUNO_API_KEY=...`（CMD）或 `$env:SUNO_API_KEY="..."`（PowerShell） |
| `~/.suno/config.json` | `%USERPROFILE%\.suno\config.json` |
| `curl ... \| jq ...` | Git Bash 中相同语法；PowerShell 中用 `curl.exe` |

**重要**：PowerShell 的 `curl` 是 `Invoke-WebRequest` 的别名，不是真正的 curl。在 PowerShell 中必须用 `curl.exe`：
```powershell
# PowerShell 中
curl.exe -s -X POST https://apibox.erweima.ai/api/v2/suno/submit/music ...

# 或者在 Git Bash 中直接用 curl（推荐）
curl -s -X POST https://apibox.erweima.ai/api/v2/suno/submit/music ...
```

---

### minimax-music-playlist

**兼容性：部分兼容（Apple Music 数据源不可用）**

此 Skill 支持三种数据来源：

| 数据来源 | macOS | Windows |
|---------|-------|---------|
| Apple Music（osascript 查询） | 可用 | **不可用** |
| Spotify（导出 ZIP 导入） | 可用 | 可用 |
| 手动输入 | 可用 | 可用 |

**Windows 上的替代方案：**

1. **Spotify 导出**（推荐）：
   - 访问 https://www.spotify.com/account/privacy/ 申请数据导出
   - 下载 ZIP → 解压 → Skill 自动解析 `StreamingHistory` JSON

2. **手动输入**：直接告诉 Claude 你喜欢的歌手和风格

3. **Apple Music 数据导出**（绕过方案）：
   - 在 macOS 上先用 osascript 导出一次播放记录
   - 保存为 JSON 文件带到 Windows 上使用

其余功能（歌单生成、封面生成、并行生成 5 首）完全一致。

---

### buddy-sings

**兼容性：完全兼容**

| macOS 写法 | Windows 适配 |
|-----------|-------------|
| `~/Music/minimax-gen/` | `%USERPROFILE%\Music\minimax-gen\` |
| `afplay file.mp3` | `mpv --no-video file.mp3` |
| `~/.claude.json` | `%USERPROFILE%\.claude.json` |

宠物设置（`/buddy` 命令）和 voice identity 缓存在 Claude Code 配置中，跨平台自动管理。

---

## 3. 音频播放器配置

所有 Skill 共用相同的播放器检测逻辑，优先级：`mpv` > `ffplay` > `afplay`（macOS）。

### Windows 推荐：安装 mpv

```powershell
winget install mpv.net
```

安装后所有 Skill 的播放功能自动可用，无需额外配置。

### 播放命令对照

| 播放器 | 命令 | 控制 |
|-------|------|------|
| mpv | `mpv --no-video file.mp3` | Space 暂停，q 退出，方向键快进 |
| ffplay | `ffplay -nodisp -autoexit file.mp3` | q 退出 |
| afplay | `afplay file.mp3`（仅 macOS） | Ctrl+C 停止 |

---

## 4. 路径对照速查

| 用途 | macOS | Windows |
|------|-------|---------|
| MiniMax 输出 | `~/Music/minimax-gen/` | `%USERPROFILE%\Music\minimax-gen\` |
| Suno 输出 | `~/Music/suno-gen/` | `%USERPROFILE%\Music\suno-gen\` |
| 歌单输出 | `~/Music/minimax-gen/playlists/` | `%USERPROFILE%\Music\minimax-gen\playlists\` |
| MiniMax 凭证 | `~/.mmx/config.json` | `%USERPROFILE%\.mmx\config.json` |
| Suno 凭证 | `~/.suno/config.json` | `%USERPROFILE%\.suno\config.json` |
| Claude 配置 | `~/.claude.json` | `%USERPROFILE%\.claude.json` |

> **注意：** Claude Code 在 Windows 上运行时，Skill 中的 `~/` 路径由 shell 自动展开。如果使用 Git Bash，`~` 会正确解析为 `%USERPROFILE%`。如果使用 PowerShell，需要手动替换为 `$env:USERPROFILE`。

---

## 5. Shell 环境建议

Skill 脚本主要使用 Bash 语法。Windows 上推荐方案：

| 方案 | 适合场景 | 安装方式 |
|------|---------|---------|
| **Git Bash**（推荐） | 所有 Skill 脚本 | 安装 Git for Windows 自带 |
| **WSL 2** | 需要完整 Linux 环境 | `wsl --install` |
| **PowerShell** | mmx-cli、curl.exe 等原生工具 | 系统自带 |

Claude Code 在 Windows 上通常通过 Git Bash 执行 Bash 命令，所以大多数 Skill 脚本无需修改即可运行。

---

## 6. 快速部署清单

```
[ ] 安装 Node.js：winget install OpenJS.NodeJS.LTS
[ ] 安装 Git：winget install Git.Git
[ ] 安装 mpv：winget install mpv.net
[ ] 安装 jq：winget install jqlang.jq
[ ] 安装 mmx-cli：npm install -g mmx-cli
[ ] 认证 MiniMax：mmx auth login --api-key sk-xxxxx
[ ] 安装 Skills：npx skills add wanhuahua0108/claude_audio_share -y -g
[ ] 创建输出目录：mkdir "%USERPROFILE%\Music\minimax-gen" "%USERPROFILE%\Music\suno-gen"
[ ] （可选）配置 Suno API Key
[ ] 验证：mmx music generate --prompt "test" --instrumental --out "%USERPROFILE%\Music\minimax-gen\test.mp3"
```
