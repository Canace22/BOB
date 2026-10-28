param(
    [string]$PackageDirectory = 'G:/鲸落万物生/builds/须门遗港-v0.5-参考图可玩关卡',
    [string]$EvidenceRoot = 'G:/鲸落万物生/BOB/godot/first-level-artmatch/evidence',
    [string]$AudioDriver = 'Dummy',
    [int]$TimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$evidenceDirectory = Join-Path $EvidenceRoot "package-normal-close-$stamp"
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
$executable = Join-Path $PackageDirectory 'Whalefall.exe'
$logFile = Join-Path $evidenceDirectory 'run.log'
$arguments = @('--verbose', '--audio-driver', $AudioDriver, '--log-file', ('"' + $logFile + '"'))
# An interactive game window is intentional here: the tester must inspect and close it normally.
$gameProcess = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $PackageDirectory -PassThru
Write-Host 'Inspect the game, then close its window with X or Alt+F4. Do not terminate the process.'
$exited = $gameProcess.WaitForExit($TimeoutSeconds * 1000)
$logText = if (Test-Path -LiteralPath $logFile) { Get-Content -LiteralPath $logFile -Raw } else { '' }
$cleanupObserved = $logText -match 'AUDIO_SHUTDOWN'
$errors = @($logText -split "`r?`n" | Where-Object { $_ -match '(ERROR:|WARNING:|Leaked instance)' })
$exitCode = if ($exited) { $gameProcess.ExitCode } else { $null }
$result = [ordered]@{
    package = $executable
    sha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant()
    process_id = $gameProcess.Id
    audio_driver = $AudioDriver
    close_method = 'Tester normal window close; no forced termination or --quit-after'
    process_exited = $exited
    exit_code = $exitCode
    cleanup_observed = $cleanupObserved
    errors_and_warnings = $errors
    pass = ($exited -and $exitCode -eq 0 -and $cleanupObserved -and $errors.Count -eq 0)
    limitations = @('Dummy audio does not verify audible output.', 'If timed out, process remains running; no kill is performed.')
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidenceDirectory 'result.json') -Encoding utf8
Write-Host "Evidence: $evidenceDirectory"
if (-not $result.pass) { exit 1 }
