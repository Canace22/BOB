$ErrorActionPreference = 'Stop'
$atlasRoot = 'G:\鲸落万物生\outputs\鲸落万物生_V5.1_地图深化'
$archivePath = 'G:\鲸落万物生\outputs\鲸落万物生_V5.1_全地图原画完整版.zip'
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists; inspect before replacing.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($atlasRoot, $archivePath, [System.IO.Compression.CompressionLevel]::Optimal, $true)
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
$checked = 0
try {
    $parentPrefix = (Split-Path -Leaf $atlasRoot) + '/'
    foreach ($entry in $archive.Entries) {
        if ($entry.FullName.EndsWith('/')) { continue }
        if (-not $entry.FullName.StartsWith($parentPrefix)) { throw ('Unexpected path: ' + $entry.FullName) }
        $relativePath = $entry.FullName.Substring($parentPrefix.Length)
        $sourcePath = Join-Path $atlasRoot $relativePath
        $sourceFile = Get-Item -LiteralPath $sourcePath
        if ($entry.Length -ne $sourceFile.Length) { throw ('Size mismatch: ' + $relativePath) }
        $entryStream = $entry.Open()
        $digest = [System.Security.Cryptography.SHA256]::Create()
        try { $entryHash = [BitConverter]::ToString($digest.ComputeHash($entryStream)).Replace('-', '') }
        finally { $entryStream.Dispose(); $digest.Dispose() }
        $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        if ($entryHash -ne $sourceHash) { throw ('Hash mismatch: ' + $relativePath) }
        $checked++
    }
    $sourceCount = (Get-ChildItem -LiteralPath $atlasRoot -Recurse -File | Measure-Object).Count
    if ($checked -ne $sourceCount) { throw 'Archive file count mismatch' }
}
finally { $archive.Dispose() }
[PSCustomObject]@{ Archive=$archivePath; VerifiedFiles=$checked; Bytes=(Get-Item -LiteralPath $archivePath).Length; AllHashesMatch=$true } | ConvertTo-Json
