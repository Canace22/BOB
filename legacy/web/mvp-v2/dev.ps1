param([int]$Port = 4176)
$ErrorActionPreference = 'Stop'
$previewDir = Join-Path $PSScriptRoot '.preview'
$nodeCommand = (Get-Command node -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $previewDir -Force | Out-Null
$probe = [System.Net.Sockets.TcpClient]::new()
$occupied = $false
try { $pending = $probe.ConnectAsync('127.0.0.1', $Port); $occupied = $pending.Wait(800) -and $probe.Connected } catch { } finally { $probe.Dispose() }
if ($occupied) {
    Write-Output "开发端口 $Port 已有服务：http://127.0.0.1:$Port/"
    exit 0
}
$previousPort = $env:PORT
try {
    $env:PORT = "$Port"
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $process = Start-Process -FilePath $nodeCommand -ArgumentList ('"' + (Join-Path $PSScriptRoot 'server.mjs') + '"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $previewDir "dev-$stamp.log") -RedirectStandardError (Join-Path $previewDir "dev-$stamp.err.log")
} finally { $env:PORT = $previousPort }
$process.Id | Set-Content -LiteralPath (Join-Path $previewDir 'dev.pid')
Write-Output "开发预览已启动（PID $($process.Id)）：http://127.0.0.1:$Port/"
Write-Output '此端口直接读取源码；稳定试玩使用 4175。'
