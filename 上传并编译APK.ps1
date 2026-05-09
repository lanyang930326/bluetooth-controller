# ============================================================
# 蓝牙控制器 APK 一键编译脚本
# 使用前请先完成【前置步骤】中的 GitHub 账号注册
# ============================================================

param(
    [string]$RepoUrl = "",
    [string]$UserName = "",
    [string]$UserEmail = ""
)

$ProjectDir = "c:\Users\Administrator\WorkBuddy\20260509150415\bluetooth_app"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  蓝牙控制器 APK 云端编译脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 检查 Git ──
Write-Host "[1/5] 检查 Git 安装..." -ForegroundColor Yellow
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "  Git 未安装，正在下载安装..." -ForegroundColor Red
    $gitInstaller = "$env:TEMP\git-installer.exe"
    Write-Host "  正在下载 Git for Windows..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe" -OutFile $gitInstaller -UseBasicParsing
    Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext,ext\reg,ext\reg\shellhere,assoc,assoc_sh" -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "  Git 安装完成！" -ForegroundColor Green
} else {
    Write-Host "  Git 已安装: $(git --version)" -ForegroundColor Green
}

# ── 收集参数 ──
Write-Host ""
Write-Host "[2/5] 配置 GitHub 信息..." -ForegroundColor Yellow

if (-not $RepoUrl) {
    Write-Host ""
    Write-Host "  请输入你的 GitHub 仓库地址" -ForegroundColor White
    Write-Host "  格式：https://github.com/你的用户名/bluetooth-controller.git" -ForegroundColor Gray
    $RepoUrl = Read-Host "  仓库地址"
}
if (-not $UserName) {
    $UserName = Read-Host "  你的 GitHub 用户名"
}
if (-not $UserEmail) {
    $UserEmail = Read-Host "  你的 GitHub 邮箱"
}

# ── 初始化 Git ──
Write-Host ""
Write-Host "[3/5] 初始化本地 Git 仓库..." -ForegroundColor Yellow

Set-Location $ProjectDir

if (Test-Path ".git") {
    Write-Host "  Git 仓库已存在，跳过初始化" -ForegroundColor Gray
} else {
    git init
    git config user.name $UserName
    git config user.email $UserEmail
    Write-Host "  Git 仓库初始化完成" -ForegroundColor Green
}

# ── 添加文件 ──
Write-Host ""
Write-Host "[4/5] 添加项目文件..." -ForegroundColor Yellow
git add -A
git status --short
git commit -m "feat: 蓝牙控制器APP初始版本 - 支持BLE扫描/连接/上升停止下降控制"
Write-Host "  提交完成" -ForegroundColor Green

# ── 推送到 GitHub ──
Write-Host ""
Write-Host "[5/5] 推送到 GitHub（将触发自动编译）..." -ForegroundColor Yellow

$branchName = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $branchName -or $branchName -eq "HEAD") {
    $branchName = "main"
    git checkout -b main
}

git remote remove origin 2>$null
git remote add origin $RepoUrl

Write-Host ""
Write-Host "  正在推送代码，可能需要输入 GitHub 凭据..." -ForegroundColor White
Write-Host "  提示：GitHub 不再支持密码登录，请使用 Personal Access Token (PAT) 作为密码" -ForegroundColor Gray
Write-Host "  PAT 获取方式：GitHub → Settings → Developer settings → Personal access tokens → Generate new token" -ForegroundColor Gray
Write-Host ""

git push -u origin $branchName --force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  推送成功！GitHub Actions 已开始编译" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  查看编译进度：" -ForegroundColor White
$repoBase = $RepoUrl -replace "\.git$", ""
Write-Host "  $repoBase/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "  编译完成后下载 APK：" -ForegroundColor White
Write-Host "  $repoBase/releases" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ⏱ 预计编译时间：5~10 分钟" -ForegroundColor Yellow
Write-Host ""
