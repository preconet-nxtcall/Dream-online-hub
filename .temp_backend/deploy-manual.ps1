<#
.SYNOPSIS
    Automated Deployment Script for FairBiz & Chat Application.

.DESCRIPTION
    Packages project files, transfers them via SSH/SCP with automated password authentication,
    extracts them, and executes Docker Compose to rebuild and run containers.

.PARAMETER ServerUser
    The SSH username for your server (default: 'root').

.PARAMETER ServerIp
    The IP or domain of your remote server (default: '103.212.120.43').

.PARAMETER ServerPass
    The SSH root password (default: configured with your server password).

.PARAMETER RemoteDir
    The project directory on the server (default: '/var/www/fairbiz').

.PARAMETER ComposeFile
    The compose file to run (default: 'docker-compose.dream.yml').

.PARAMETER SkipUpload
    Skip file packaging & upload; only run remote docker compose commands.

.PARAMETER SkipRebuild
    Skip remote docker compose execution; only upload updated files.

.EXAMPLE
    .\deploy-manual.ps1
#>

[CmdletBinding()]
param (
    [string]$ServerUser  = "root",
    [string]$ServerIp    = "103.212.120.43",
    [string]$ServerPass  = "E#@TLB&&W@S#",
    [string]$RemoteDir   = "/var/www/fairbiz",
    [string]$ComposeFile = "docker-compose.dream.yml",
    [switch]$SkipUpload,
    [switch]$SkipRebuild
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         FairBiz Automated Server Deployment             " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Target Server  : $ServerUser@$ServerIp" -ForegroundColor Yellow
Write-Host "  Remote Folder  : $RemoteDir" -ForegroundColor Yellow
Write-Host "  Compose File   : $ComposeFile" -ForegroundColor Yellow
Write-Host "  Auth Mode      : Automated SSH / Password / Key" -ForegroundColor Yellow
Write-Host "  Started At     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

# Resolve local project directory (fairbiz directory)
$LocalDir = $PSScriptRoot
if (-not (Test-Path "$LocalDir\docker-compose.dream.yml")) {
    if (Test-Path "$LocalDir\fairbiz\docker-compose.dream.yml") {
        $LocalDir = "$LocalDir\fairbiz"
    } else {
        Write-Error "Could not locate project root directory with docker-compose.dream.yml."
    }
}

Set-Location $LocalDir
$TarFile = "$LocalDir\fairbiz-deploy.tar.gz"

# Configure OpenSSH AskPass to automate password entry
$AskPassScript = "$LocalDir\.fairbiz_askpass.cmd"
$EscapedPass = $ServerPass.Replace("&", "^&").Replace("%", "%%")
"@echo $EscapedPass" | Set-Content -Path $AskPassScript -Encoding ASCII -Force

$env:SSH_ASKPASS = $AskPassScript
$env:SSH_ASKPASS_REQUIRE = "force"
$env:DISPLAY = "dummy:0"

$SshCommonOpts = @(
    "-o", "StrictHostKeyChecking=accept-new",
    "-o", "ConnectTimeout=20"
)

try {
    # ── STEP 0: Auto-configure SSH Key (Passwordless future logins) ─
    $LocalSshDir = "$env:USERPROFILE\.ssh"
    $LocalPubKey = "$LocalSshDir\id_ed25519.pub"
    $LocalPrivKey = "$LocalSshDir\id_ed25519"
    if (-not (Test-Path $LocalPubKey)) {
        if (-not (Test-Path $LocalSshDir)) { New-Item -ItemType Directory -Path $LocalSshDir -Force | Out-Null }
        & ssh-keygen.exe -t ed25519 -N '""' -f "$LocalPrivKey" -q
    }

    if (Test-Path $LocalPubKey) {
        $pubKeyStr = (Get-Content $LocalPubKey -Raw).Trim()
        if ($pubKeyStr) {
            $keySetupCmd = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && (grep -qF '$pubKeyStr' ~/.ssh/authorized_keys || echo '$pubKeyStr' >> ~/.ssh/authorized_keys)"
            & ssh.exe @SshCommonOpts "${ServerUser}@${ServerIp}" "$keySetupCmd" 2>$null
        }
    }

    # ── STEP 1: Package Files ──────────────────────────────────
    if (-not $SkipUpload) {
        Write-Host "`n[1/4] Packaging local project files..." -ForegroundColor Cyan

        # Remove previous archive if exists
        if (Test-Path $TarFile) {
            Remove-Item -Force $TarFile
        }

        # Build tarball excluding node_modules, logs, and vcs files
        $tarArgs = @(
            "-czf", $TarFile,
            "--exclude=chat/node_modules",
            "--exclude=.git",
            "--exclude=.vscode",
            "--exclude=*.log",
            "--exclude=fairbiz-deploy.tar.gz",
            "chat",
            "office-manage",
            "docker-compose.dream.yml",
            "nginx.dream.conf"
        )

        & tar.exe @tarArgs
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $TarFile)) {
            throw "Failed to create deployment archive."
        }

        $TarSizeMB = [math]::Round((Get-Item $TarFile).Length / 1MB, 2)
        Write-Host "   Archive created successfully ($TarSizeMB MB)." -ForegroundColor Green

        # ── STEP 2: Transfer Archive via SCP ───────────────────
        Write-Host "`n[2/4] Uploading archive to $ServerUser@${ServerIp}:/tmp/..." -ForegroundColor Cyan
        & scp.exe @SshCommonOpts "$TarFile" "${ServerUser}@${ServerIp}:/tmp/fairbiz-deploy.tar.gz"
        if ($LASTEXITCODE -ne 0) {
            throw "SCP upload failed. Please verify network connection."
        }
        Write-Host "   Upload complete." -ForegroundColor Green

        # ── STEP 3: Extract on Server ──────────────────────────
        Write-Host "`n[3/4] Extracting files on remote server..." -ForegroundColor Cyan
        $extractCommands = @(
            "mkdir -p '$RemoteDir'",
            "tar -xzf /tmp/fairbiz-deploy.tar.gz -C '$RemoteDir'",
            "rm -f /tmp/fairbiz-deploy.tar.gz",
            "echo 'Extraction done.'"
        ) -join " && "

        & ssh.exe @SshCommonOpts "${ServerUser}@${ServerIp}" "$extractCommands"
        if ($LASTEXITCODE -ne 0) {
            throw "Remote extraction failed."
        }
        Write-Host "   Files successfully extracted into $RemoteDir." -ForegroundColor Green
    } else {
        Write-Host "`n[INFO] Skipping file upload as requested." -ForegroundColor Yellow
    }

    # ── STEP 4: Docker Compose Rebuild & Up ────────────────────
    if (-not $SkipRebuild) {
        Write-Host "`n[4/4] Running Docker Compose on remote server..." -ForegroundColor Cyan
        
        $remoteDeployCmd = "cd '$RemoteDir' && if docker compose version >/dev/null 2>&1; then DCMD='docker compose -f $ComposeFile'; else DCMD='docker-compose -f $ComposeFile'; fi && `$DCMD down 2>/dev/null; docker rm -f fb_mysql fb_office_manage fb_chat_backend fb_mongodb fb_redis fb_nginx 2>/dev/null; echo '[Remote] Running: ' `$DCMD up -d --build && `$DCMD up -d --build && echo '[Remote] Containers:' && `$DCMD ps"

        & ssh.exe @SshCommonOpts "${ServerUser}@${ServerIp}" "$remoteDeployCmd"
        if ($LASTEXITCODE -ne 0) {
            throw "Remote docker-compose build/startup failed."
        }
        Write-Host "   Docker containers updated and running!" -ForegroundColor Green
    } else {
        Write-Host "`n[INFO] Skipping Docker rebuild as requested." -ForegroundColor Yellow
    }

    $ElapsedTime = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "  Deployment Completed Successfully in ${ElapsedTime}s! " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  To view live container logs on your server, run:" -ForegroundColor Yellow
    Write-Host "  ssh @SshCommonOpts ${ServerUser}@${ServerIp} `"cd $RemoteDir && docker compose -f $ComposeFile logs -f`"" -ForegroundColor Gray

} catch {
    Write-Host "`n[ERROR] Deployment failed: $_" -ForegroundColor Red
} finally {
    # Clean up local temporary tarball & askpass helper
    if (Test-Path $TarFile) {
        Remove-Item -Force $TarFile -ErrorAction SilentlyContinue
    }
    if (Test-Path $AskPassScript) {
        Remove-Item -Force $AskPassScript -ErrorAction SilentlyContinue
    }
    Remove-Item env:\SSH_ASKPASS -ErrorAction SilentlyContinue
    Remove-Item env:\SSH_ASKPASS_REQUIRE -ErrorAction SilentlyContinue
    Remove-Item env:\DISPLAY -ErrorAction SilentlyContinue
}
