$ErrorActionPreference = 'Stop'
$sourceDir = 'G:\鲸落万物生\outputs\鲸落万物生_V4.3_玩法逐帧图解'
$destinationDir = 'C:\Users\Kingsoft\Documents\Codex\2026-10-16\new-chat-2\outputs\鲸落万物生_V4.3_玩法逐帧图解'
$archivePath = 'C:\Users\Kingsoft\Documents\Codex\2026-10-16\new-chat-2\outputs\鲸落万物生_V4.3_玩法逐帧原画与设计.zip'
$plates = Get-Content -LiteralPath "$sourceDir\data\图板设计.json" -Raw | ConvertFrom-Json
foreach ($plate in $plates) {
  if ($plate.crop) {
    if ($plate.boxes.Count -ne $plate.steps.Count) { throw "Crop count mismatch: $($plate.id)" }
    foreach ($box in $plate.boxes) {
      if ($box[0] -lt 0 -or $box[1] -lt 0 -or $box[2] -gt 1 -or $box[3] -gt 1 -or $box[2] -le $box[0] -or $box[3] -le $box[1]) { throw "Invalid crop: $($plate.id)" }
    }
  }
}
$review = @'

## 定向修订复核

- C01/U01：调息只使用左腰同一盏菌灯，删除重复手持灯。
- R4W：接珠用手持骨鸣器近身迎击；攻击前先脱离锚环。
- R3W：误画的空中下劈改为落地侧向反击。
- E02：多余叉齿修正为双叉；E01：膜缘鳐修正为浅色半透明膜体。
- T01：纠正承重前后状态；薄骨片由重量触发，不依赖未定义魔法。
- W01：区域归位到鲸头耳腔、肺心、胃肠与脊骨；鲸尾改为侧视的扁平软组织尾叶。
- 共8张图经定向修订，其中世界图两次修订；修订后的图已人工视觉复核。
- 逐格视窗边界与说明条数已经静态校验，均处于原图范围内。
'@
Add-Content -LiteralPath "$sourceDir\验收记录.md" -Value $review -Encoding utf8
New-Item -ItemType Directory -Path "$sourceDir\data\生成记录" -Force | Out-Null
foreach ($plate in $plates) {
  $originalMeta = "G:\鲸落万物生\BOB\work\v43-$($plate.id).json"
  $editMeta = "G:\鲸落万物生\BOB\work\v43-$($plate.id)-edit.json"
  Copy-Item -LiteralPath $originalMeta -Destination "$sourceDir\data\生成记录" -Force
  if (Test-Path -LiteralPath $editMeta) { Copy-Item -LiteralPath $editMeta -Destination "$sourceDir\data\生成记录" -Force }
}
if (Test-Path -LiteralPath $destinationDir) { throw 'Destination already exists; inspect before overwrite.' }
Copy-Item -LiteralPath $sourceDir -Destination $destinationDir -Recurse
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceDir -Recurse -File)
foreach ($file in $sourceFiles) {
  $relative = $file.FullName.Substring($sourceDir.Length + 1)
  $copy = Join-Path $destinationDir $relative
  if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) { throw "Copy mismatch: $relative" }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists; inspect before overwrite.' }
[System.IO.Compression.ZipFile]::CreateFromDirectory($destinationDir, $archivePath, [System.IO.Compression.CompressionLevel]::Optimal, $true)
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
  $pngCount = @($archive.Entries | Where-Object { $_.FullName -match '/images/[^/]+\.png$' }).Count
  if ($pngCount -ne 24) { throw "Archive has $pngCount PNG boards" }
  $entryCount = $archive.Entries.Count
} finally { $archive.Dispose() }
[pscustomobject]@{ Plates = $plates.Count; Notes = ($plates.steps | Measure-Object).Count; FilesVerified = $sourceFiles.Count; ZipEntries = $entryCount; ArchiveMB = [math]::Round((Get-Item -LiteralPath $archivePath).Length / 1MB, 1); Book = "$destinationDir\原画册.html"; Archive = $archivePath } | ConvertTo-Json
