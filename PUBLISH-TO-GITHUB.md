# 把本项目发布到 GitHub — 执行手册（交给 agent 执行）

> 目标：把 `C:\Users\Dohn\Desktop\FPS帧率图改造` 这个本地 git 仓库发布为 **公开仓库** `game-turbo-fps-graph`。
> 执行环境：**同一台 Windows 机器**（PowerShell 或 bash 均可，下文给 PowerShell）。所有路径均为本机绝对路径。
> 当前状态：**已发布**到 <https://github.com/Monkey-Dohn/game-turbo-fps-graph>（Public，默认分支 `main`，已推 `v17` tag）。
> 发布记录：`main` 已推送；`v17` tag 指向功能提交 `f94434b`。本机使用仓库 deploy key（写权限）通过 SSH 推送。

---

## 0. 已完成的准备工作（不要重复做）

| 项 | 状态 |
|---|---|
| 本地 git 仓库 | 已 `git init -b main`；功能提交 `f94434b`（`feat: restore Game Turbo FPS graph and inline FPS readout (v17)`），其后有发布手册 docs commit |
| 工作区 | `C:\Users\Dohn\Desktop\FPS帧率图改造`（目录名含中文，命令里务必加引号） |
| `.gitignore` | 已排除 `fpsgraph*.apk`、`*.idsig`、`classes.dex`、`unsigned2.apk`、`aligned.apk`、截图、`*.log` |
| 入库文件（12 个） | `.gitignore`、`AndroidManifest.xml`、`LICENSE`、`PUBLISH-TO-GITHUB.md`、`README.md`、`debug.keystore`、`docs/DEVELOPMENT.md`、`rebuild.ps1`、`src/Main.smali`、`src/PanelHook.smali`、`unsigned.apk`、`xposed_init.txt` |
| `gh` CLI | 已装 2.105.0，路径 `C:\Program Files\GitHub CLI\gh.exe`（不在 PATH 里，用绝对路径或先加 PATH） |
| SSH key | 已生成 `C:\Users\Dohn\.ssh\id_ed25519_github`（ed25519，无 passphrase），公钥见第 3 步 |
| SSH 登记 | 因发布 token 仅有 `repo` 权限，公钥已作为仓库 `game-turbo-fps-graph` 的 **deploy key（read_only=false）** 登记；不是账号级 SSH key |
| SSH 配置 | `C:\Users\Dohn\.ssh\config` 已写入：`Host github.com → HostName ssh.github.com / Port 443 / IdentityFile ~/.ssh/id_ed25519_github` |
| hosts | `C:\Windows\System32\drivers\etc\hosts` 已把 `github.com` 指向 `20.6.7.17`（原文件备份：`hosts.dsh-bak`） |
| 真机验证 | v17 已安装并在设备 `bd1a576` 上实测通过（曲线恢复、表盘隐藏、内联 `84 FPS`） |

### 关键网络事实（决定用哪条通道，不要随意改）

| 端点 | 状态 | 结论 |
|---|---|---|
| `api.github.com` | 200 稳定 | **建仓库、加公钥、查用户全走这里** |
| `github.com`（20.6.7.17） | GET 200 | 网页可开；但 **`POST /login/oauth/access_token` 被网络掐断** |
| 其它 `github.com` IP（20.205.243.166 等） | 多数超时 | 不要用 |
| `gh auth login --web` | 失败（已试 3 次） | 不要再用，见第 1 步 |
| `ssh.github.com:443` | 握手正常 | **推送走 SSH** |
| `github.com:22` | OPEN | SSH 备用通道 |
| HTTPS 推送（`https://github.com/...`） | 不可靠（POST 被掐） | **不要用 HTTPS push** |

---

## 1. 认证：只需要一个 GitHub token

**为什么不能用 `gh auth login --web`**：device flow 的最后一步 `POST https://github.com/login/oauth/access_token` 在这条网络上超时，已实测失败 3 次。不要再浪费时间去试。

### 1.1 拿 token（由**人**在浏览器完成，agent 无法代做）

- 打开 <https://github.com/settings/tokens/new>（已登录 GitHub 账号）
- Note：`game-turbo-fps-graph`
- Expiration：`30 days`
- 勾选 **`repo`**（勾它会自动带上子项）
- 拉到底 → **Generate token** → 复制 `ghp_` 开头的字符串（只显示一次）

> 用户还没有 GitHub 账号时，先到 <https://github.com/signup> 注册。
> agent 若拿不到 token，唯一需要向人请求的就是这一串字符。

### 1.2 用 token 登录 gh（agent 执行）

```powershell
$gh   = 'C:\Program Files\GitHub CLI\gh.exe'
$token = 'ghp_把这里换成真实token'

$token | & $gh auth login --hostname github.com --git-protocol ssh --with-token

& $gh auth status
& $gh api user --jq .login
```

**期望**：`auth status` 显示 `Logged in to github.com account <用户名>`；`api user` 打印你的 GitHub 用户名（后面 `<LOGIN>` 就用它）。

### 1.3 备选（token 走环境变量，避免出现在命令历史里）

```powershell
$env:GH_TOKEN = 'ghp_xxx'
& 'C:\Program Files\GitHub CLI\gh.exe' auth status
```

---

## 2. 建仓库（走 api.github.com）

```powershell
$gh  = 'C:\Program Files\GitHub CLI\gh.exe'
$dir = 'C:\Users\Dohn\Desktop\FPS帧率图改造'

Set-Location $dir
& $gh repo create game-turbo-fps-graph --public --source . --remote origin `
    --description "LSPosed module: restore the hidden frame-rate curve in MIUI/HyperOS Game Turbo and turn the FPS number into a minimal inline readout"
```

**注意**

- **不要加 `--push`**：它默认用 HTTPS 推，会卡死。建完仓库手动改 SSH remote 再推。
- 如果提示 `remote origin already exists`，跳过建仓库的 `--source/--remote`，改用：

```powershell
& $gh repo create game-turbo-fps-graph --public --description "..."
git remote add origin "git@github.com:<LOGIN>/game-turbo-fps-graph.git"
```

**期望**：`https://github.com/<LOGIN>/game-turbo-fps-graph` 建好且为空仓库。

---

## 3. 把 SSH 公钥登记到账号

公钥内容（已存在于 `C:\Users\Dohn\.ssh\id_ed25519_github.pub`）：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/hNVwHsN/3pPVttE4NIjH5cJUqvD1jTjhfxvjgpiRO dohn@game-turbo-fps-graph
```

```powershell
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
& $gh ssh-key add "C:\Users\Dohn\.ssh\id_ed25519_github.pub" --title "game-turbo-fps-graph"
& $gh ssh-key list
```

**期望**：`ssh-key list` 里出现该指纹；随后 `ssh -T git@github.com` 应返回 `Hi <LOGIN>! You've successfully authenticated...`（这条会走 `ssh.github.com:443`）。

> **本次实际走的 deploy key**：发布 token 只有 `repo` 权限，没有 `admin:public_key`，不能调 `ssh-key add`。因此把同一公钥加成了仓库 deploy key（写权限），推送仍走 SSH：
>
> ```powershell
> $pub = (Get-Content "$env:USERPROFILE\.ssh\id_ed25519_github.pub" -Raw).Trim()
> & $gh api --method POST repos/<OWNER>/game-turbo-fps-graph/keys `
>   -f title='game-turbo-fps-graph' -f key="$pub" -F read_only=false
> ```
>
> 如果 token 带 `admin:public_key`，优先用上面的账号级 `ssh-key add`。

---

## 4. 推送

```powershell
$dir = 'C:\Users\Dohn\Desktop\FPS帧率图改造'
Set-Location $dir

git remote set-url origin "git@github.com:<LOGIN>/game-turbo-fps-graph.git"
git remote -v
git push -u origin main
```

**期望**：`main -> main` 成功，输出 `branch 'main' set up to track 'origin/main'`。

**校验**

```powershell
git ls-remote origin
& 'C:\Program Files\GitHub CLI\gh.exe' repo view --json name,visibility,url,defaultBranchRef
```

期望：`visibility: PUBLIC`、`defaultBranchRef.name: main`。

---

## 5. 打版本 tag（可选但建议）

```powershell
git tag -a v17 -m "v17: fix idempotent guard (if-ne -> if-eq), null-check findClass, drop RateHook"
git push origin v17
```

> **不要**把 `fpsgraph.apk` 传进仓库（已被 `.gitignore` 挡掉）。安装包作为 **Release 附件** 发布：
>
> 已创建 `v17` Release，附件名 `game-turbo-fps-graph-v17.apk`，12,755 B，SHA256 `231B0FE06CBEFD8A3937156245ED922F0018BFB9BDF019277E2AB5FB74EBD00F`。
>
> 复现命令：`gh release create v17 --verify-tag --title "v17" --notes "..." "fpsgraph.apk"`；上传后可删除本地安装包，仓库里只保留源码 + `rebuild.ps1`。

---

## 6. 故障对照表

| 现象 | 原因 | 处理 |
|---|---|---|
| `gh auth login --web` 超时 | OAuth token 端点被掐 | 放弃 web 登录，用第 1 步的 token |
| `gh: command not found` | gh 不在 PATH | 用绝对路径 `C:\Program Files\GitHub CLI\gh.exe` |
| `git push` 卡住 / `Empty reply from server` | 走了 HTTPS | `git remote set-url origin git@github.com:<LOGIN>/<repo>.git` |
| `Permission denied (publickey)` | 公钥没登记，或 ssh 没走 443 | 重做第 3 步；确认 `~/.ssh/config` 有 `Host github.com → ssh.github.com:443` |
| 浏览器打不开 github.com | hosts 被改回/失效 | 确认 hosts 里 `20.6.7.17 github.com`；需要管理员权限写入 |
| `api.github.com` 也不通 | 网络整体波动 | 稍等重试；它此前稳定 200 |
| 仓库建好了但内容为空 | 只跑了 `repo create` 没 push | 执行第 4 步 |

---

## 7. 验收清单

- [x] token 已校验（本次用 `GH_TOKEN` 环境变量，未持久化到 gh 配置）
- [x] `https://github.com/Monkey-Dohn/game-turbo-fps-graph` 可访问且为 Public（API 校验）
- [x] 首页渲染的是项目 `README.md`
- [x] 仓库里只有 12 个文件，**没有** `fpsgraph.apk` / `classes.dex` / `unsigned2.apk` / `aligned.apk`
- [x] `main` 分支已推送（含 `f94434b` 及其后的 docs commit）
- [x] `v17` tag 已推送

---

## 8. 给 agent 的硬性约束

1. **不要**把 token 写进任何文件、git remote URL 或 commit message；用完即弃（用户可在同一页面 Delete）。
2. **不要** `git add -f` 强推被 `.gitignore` 排除的产物。
3. **不要** 回滚 `src/`、`README.md` 的 v17 改动，也不要重新构建/安装 APK。
4. **不要** 改 hosts / `~/.ssh/config`（已经验证可用），除非上述端点彻底失效。
5. 删除类操作先列清单，不要整目录清理。
6. 完成后把仓库 URL 报回来。
