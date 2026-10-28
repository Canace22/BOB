param([string]$GodotExe, [switch]$Pan)
$ErrorActionPreference = 'Stop'
if (-not $GodotExe) {
    $GodotExe = Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotExe)) { throw '请使用 -GodotExe 指定 Godot 4.7.2 可执行文件。' }
$engineVersion = & $GodotExe --version
if ($engineVersion -notmatch '^4\.7\.2\.stable') { throw "本场景固定 Godot 4.7.2，当前版本：$engineVersion" }
$previewArgs = @('--path', $PSScriptRoot, '--audio-driver', 'Dummy', 'res://scenes/environment/xumen_reference.tscn')
if ($Pan) { $previewArgs += @('--', '--pan') }
& $GodotExe @previewArgs
