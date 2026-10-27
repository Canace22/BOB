param([int]$Port = 4175)
$ErrorActionPreference = 'Stop'
$previewDir = Join-Path $PSScriptRoot '.preview'
$nodeCommand = (Get-Command node -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $previewDir -Force | Out-Null

try { $existing = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/__preview/status" -TimeoutSec 2 } catch { $existing = $null }
if ($existing.service -eq 'whalefall-preview') {
    Write-Output "稳定试玩已在运行（版本 $($existing.release)）：http://127.0.0.1:$Port/"
    exit 0
}
$probe = [System.Net.Sockets.TcpClient]::new()
$occupied = $false
try { $pending = $probe.ConnectAsync('127.0.0.1', $Port); $occupied = $pending.Wait(800) -and $probe.Connected } catch { } finally { $probe.Dispose() }
if ($occupied) { throw "端口 $Port 被其他服务使用。已保留现有进程；请先明确处理端口冲突，再启动稳定试玩。" }
if (-not (Test-Path -LiteralPath (Join-Path $previewDir 'active.json'))) {
    & $nodeCommand (Join-Path $PSScriptRoot 'publish-preview.mjs')
    if ($LASTEXITCODE -ne 0) { throw '发布试玩快照失败，服务尚未启动。' }
}

$previousPort = $env:PORT
try {
    $env:PORT = "$Port"
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $process = Start-Process -FilePath $nodeCommand -ArgumentList ('"' + (Join-Path $PSScriptRoot 'preview.mjs') + '"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $previewDir "preview-$stamp.log") -RedirectStandardError (Join-Path $previewDir "preview-$stamp.err.log")
} finally { $env:PORT = $previousPort }
$process.Id | Set-Content -LiteralPath (Join-Path $previewDir 'preview.pid')
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Milliseconds 100
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/__preview/status" -TimeoutSec 1
        if ($health.service -eq 'whalefall-preview') {
            Write-Output "稳定试玩已启动（PID $($process.Id)）：http://127.0.0.1:$Port/"
            & $nodeCommand -e 'for(const a of Object.values(require("node:os").networkInterfaces()).flat()) if(a.family==="IPv4"&&!a.internal) console.log("局域网试玩：http://"+a.address+":"+process.argv[1]+"/")' "$Port"
            Write-Output '源码修改不会改变当前试玩；发布新快照后，新打开首页才会进入新版本。'
            exit 0
        }
    } catch { }
}
throw "稳定试玩未能启动，请检查 $previewDir 下的 preview 日志。"
