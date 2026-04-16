# ACE-Step 1.5 跨平台部署指南

> macOS (Apple Silicon) + Windows (NVIDIA CUDA) 双平台配置

## 总览

| 项目 | macOS (当前) | Windows PC |
|------|-------------|------------|
| 后端 | MLX（自动） | CUDA（自动） |
| 启动脚本 | `start_api_server_macos.sh` | `start_api_server.bat` |
| Gradio UI | `start_gradio_ui_macos.sh` | `start_gradio_ui.bat` |
| Python | 3.11-3.12（uv 管理） | 3.11-3.12（uv 管理） |
| 模型文件 | 需独立下载（~10GB） | 需独立下载（~10GB） |
| Skill 脚本 | `acestep.sh`（原生 Bash） | `acestep.sh`（需 Git Bash 或 WSL） |

**代码完全一样**，差异仅在启动脚本和 GPU 后端。

---

## Windows PC 安装步骤

### Step 1: 前置工具

```powershell
# 安装 uv（Python 包管理器）
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# 安装 Git（如果没有）
winget install Git.Git

# 安装 jq（acestep.sh 需要）
winget install jqlang.jq
```

> **NVIDIA 驱动**：确保已安装最新版 [NVIDIA 驱动](https://www.nvidia.com/drivers)，CUDA 无需单独安装（PyTorch 自带）。

### Step 2: 克隆仓库 + 安装依赖

```powershell
git clone https://github.com/ACE-Step/ACE-Step-1.5.git
cd ACE-Step-1.5
uv sync
```

> 首次 `uv sync` 会下载约 2GB Python 依赖（含 PyTorch CUDA 版），耗时 3-10 分钟。

### Step 3: 启动 API Server

```powershell
# 双击或命令行运行
start_api_server.bat
```

首次启动会自动下载 3 个模型（约 10GB），之后再启动无需重复下载。

### Step 4: 配置 Skill

ACE-Step 自带的 6 个 Skills 在 `.claude/skills/` 目录下，Claude Code 会自动识别。

Skill 的 `acestep.sh` 脚本需要 Bash 环境，Windows 上有两种方案：

**方案 A：Git Bash（推荐）**
```
安装 Git for Windows 后自带 Git Bash
在 Claude Code 中 acestep.sh 可以通过 Git Bash 运行
```

**方案 B：WSL**
```powershell
wsl --install
# 然后在 WSL 中运行 acestep.sh
```

### Step 5: 验证

```powershell
# 方式一：浏览器访问
# http://127.0.0.1:8001/docs  （API 文档）

# 方式二：Gradio Web UI
start_gradio_ui.bat
# 浏览器打开 http://127.0.0.1:7860

# 方式三：通过 Skill 脚本（Git Bash 中）
cd .claude/skills/acestep/
bash scripts/acestep.sh health
bash scripts/acestep.sh generate "A cheerful pop song" --duration 30
```

---

## GPU 显存与模型选择

ACE-Step **自动检测** GPU 显存并选择最优配置，但也可手动指定。

### 自动配置（默认）

| PC 显存 | DiT 模型 | LM 模型 | 效果 |
|---------|---------|---------|------|
| 4-6 GB | 2B turbo | 无（DiT only） | 基本可用，INT8 量化 |
| 6-8 GB | 2B turbo | 0.6B | 良好 |
| 8-16 GB | 2B turbo/sft | 0.6B-1.7B | 很好 |
| 16-24 GB | XL turbo | 1.7B | 优秀 |
| 24+ GB | XL sft | 4B | 最佳 |

### 手动指定（编辑 `.env` 文件）

```env
# 在 ACE-Step-1.5 目录下创建 .env 文件

# DiT 模型（二选一）
ACESTEP_CONFIG_PATH=acestep-v15-turbo      # 2B，快速
# ACESTEP_CONFIG_PATH=acestep-v15-xl-turbo  # XL，高质量（需 16+ GB）

# LM 模型（三选一）
ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-0.6B  # 小（6+ GB 显存）
# ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-1.7B  # 中（8+ GB 显存，推荐）
# ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-4B    # 大（24+ GB 显存）

# 禁用 LM（仅 DiT，显存不够时）
# ACESTEP_INIT_LLM=false
```

### macOS vs Windows 模型对比

| | macOS M4 Max 64GB | Windows RTX 4070 12GB | Windows RTX 4090 24GB |
|---|---|---|---|
| DiT | 2B turbo | 2B turbo | XL turbo |
| LM | 1.7B（MLX） | 1.7B | 1.7B-4B |
| 速度 | ~30s/首 | ~10s/首 | ~5s/首 |
| 质量 | 很好 | 很好 | 最佳 |

> Windows NVIDIA 显卡在推理速度上通常比 Apple Silicon 快，因为 CUDA 生态更成熟。

---

## 两台机器的配置差异

### 需要改的

| 配置 | macOS | Windows |
|------|-------|---------|
| 启动脚本 | `start_api_server_macos.sh` | `start_api_server.bat` |
| Gradio | `start_gradio_ui_macos.sh` | `start_gradio_ui.bat` |
| Bash | 原生支持 | 需 Git Bash 或 WSL |

### 不需要改的

- `config.json`（`api_url: http://127.0.0.1:8001` 两端一样）
- Skill 文件（`.claude/skills/` 完全通用）
- 歌曲 Prompt / 歌词 / 生成参数
- 输出目录结构（`acestep_output/`）

---

## 快速迁移清单

在 PC 上部署时，按顺序检查：

```
[ ] 安装 uv：powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
[ ] 安装 Git：winget install Git.Git
[ ] 安装 jq：winget install jqlang.jq
[ ] 确认 NVIDIA 驱动已安装且最新
[ ] git clone https://github.com/ACE-Step/ACE-Step-1.5.git
[ ] cd ACE-Step-1.5 && uv sync
[ ] 运行 start_api_server.bat（首次会下载 ~10GB 模型）
[ ] （可选）创建 .env 文件手动指定模型
[ ] 在 Git Bash 中测试：bash .claude/skills/acestep/scripts/acestep.sh health
```

---

## 常见问题

| 问题 | 解决 |
|------|------|
| `uv sync` 报 CUDA 错误 | 确认 NVIDIA 驱动已安装，重启终端后重试 |
| acestep.sh 无法运行 | Windows 下用 Git Bash 执行，不要用 PowerShell |
| 模型下载慢 | 编辑 `.env` 添加 `DOWNLOAD_SOURCE=modelscope`（国内镜像） |
| 显存不足 OOM | 编辑 `.env` 设置更小的模型，或设 `ACESTEP_INIT_LLM=false` |
| 两台电脑生成结果不同 | 正常现象——不同 GPU 后端（MLX vs CUDA）、不同精度会有差异 |
