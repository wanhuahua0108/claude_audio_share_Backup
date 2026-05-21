# CLAUDE.md — claude_audio_share

> AI Music Agent 安装包:5 个音乐生成 skills(MiniMax + Suno + ACE-Step + buddy-sings + tts-speak)的**可分享 setup 项目**,供其他人 clone + setup.sh 一键装。**不是日常工作目录**,user 自己的实际 skill 在 `~/.claude/skills/`,这里是公开分发版。

## 当前状态 (2026-05-21)

- **Active** ⚠️ — 不算 daily 项目,**主要在新版 skill 写好后同步进来 + 发布**(用户分享给同事 / 朋友 setup AI 音乐 agent)
- **GitHub**: 可能 public(share 项目),具体 repo URL 在 README
- **本地路径**:`pc-work-new` 上 `D:\AI\Claude\claude_audio_share`

## 怎么用

- **主入口**:`setup.sh`(end-user 一键装脚本)
- **skills 在**:`skills/` 目录(5 个 skill 的 SKILL.md + scripts)
- **docs 在**:`docs/`

## 跟 user 实际工作 skills 的关系

- ✅ 这里的 skills 是 **export / share 版本**,可能比 `~/.claude/skills/` 落后几天
- ✅ user 在 vault session 改了 skill → 验证 OK → 才同步到这里 → push GitHub 让别人 setup 拿到
- ❌ 不要在这里改 skill 主体逻辑(那是 `~/.claude/skills/` 的工作),只在这里维护 setup.sh / README / 分发相关

## 关键文档

- [README.md](./README.md) — end-user 安装指南(完整 setup steps:Homebrew / Node / MiniMax CLI / Suno API key / etc.)
- `setup.sh` — 一键装脚本

## 重要约束

- **不存任何 API key** — README 教 user 自己注册 MiniMax / Suno key,我们不提供
- **跨平台**:user 实测 macOS + Windows,setup.sh 主要 macOS,Windows 走 Git Bash 兼容(最近 commit 都是 Windows compat fixes)
- **MiniMax 免费额度**:music-2.6-free 每天 100 次 API,够 demo / 个人用

## 最近活动

```
3452ed1 fix: buddy-sings add --model music-2.6 + mkdir -p (Windows compat)
1fdd943 feat: add tts-speak skill + Windows compatibility fixes for music skills
9e0a6e2 Add ACE-Step cross-platform deployment guide
```

## next session 接手 checklist

1. SessionStart hook 自动 `git pull`
2. `git log --oneline -10` 看最近活动
3. **如果 user 提到"新加了个 skill"或"改了 skill"** → 多半是要从 `~/.claude/skills/` 同步过来(`rsync` 或 `cp` 然后 commit)
4. 不要在这里直接编辑 skill 主逻辑 — 那是 `~/.claude/skills/` 的活儿
