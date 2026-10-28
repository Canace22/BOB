$ErrorActionPreference = 'Stop'
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw '请在管理员 PowerShell 中执行此脚本。' }
$ruleName = 'Whalefall design book LAN 8876'
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8876 -LocalAddress 10.11.140.20 -RemoteAddress 10.0.0.0/8 -Profile Any
}
Write-Output '公司 10.x 内网已允许访问 http://10.11.140.20:8876/index.html'
