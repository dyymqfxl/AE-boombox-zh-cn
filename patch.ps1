param(
    [ValidateSet('Install','Uninstall')][string]$Mode = 'Install',
    [string]$ExtensionPath = "${env:ProgramFiles(x86)}\Common Files\Adobe\CEP\extensions\com.mtmograph.boombox"
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Get-Hash([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Write-Utf8([string]$Path, [string]$Text) { [IO.File]::WriteAllText($Path, $Text, $utf8) }
$target = (Resolve-Path -LiteralPath $ExtensionPath).Path
$index = Join-Path $target 'index.html'
$bundle = Join-Path $target 'cep.js'
$backup = Join-Path $target 'boombox-zh-cn-backup-v1'
$statePath = Join-Path $backup 'state.json'
$files = @('boombox-zh-cn.dictionary.js','boombox-zh-cn.js','boombox-zh-cn.css','cep.zh-cn.js')
if ($Mode -eq 'Uninstall') {
    if (!(Test-Path -LiteralPath $statePath)) { throw 'No Chinese patch backup found.' }
    $state = [IO.File]::ReadAllText($statePath) | ConvertFrom-Json
    $originalIndex = Join-Path $backup 'index.html'
    if ((Get-Hash $originalIndex) -ne $state.originalIndexHash) { throw 'Backup checksum mismatch; refusing restore.' }
    $indexHash = Get-Hash $index
    if ($indexHash -ne $state.installedIndexHash -and $indexHash -ne $state.originalIndexHash) { throw 'index.html changed after installation. Restore manually from the backup to avoid overwriting newer changes.' }
    foreach ($name in $files) {
        $file = Join-Path $target $name
        if ((Test-Path -LiteralPath $file) -and (Get-Hash $file) -ne $state.payloadHashes.$name) { throw "Modified patch file: $name. Refusing to delete local changes." }
    }
    [IO.File]::WriteAllBytes($index, [IO.File]::ReadAllBytes($originalIndex))
    foreach ($name in $files) {
        $file = Join-Path $target $name
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
    }
    # Keep a recoverable backup/manifest; allow a later clean reinstall.
    Write-Output 'Chinese patch removed. Original index restored. Close and reopen Boombox.'
    exit 0
}
$spec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'patch-spec.json')) | ConvertFrom-Json
if ((Get-Hash $bundle) -ne $spec.sourceSha256) { throw 'Unsupported cep.js version. No files changed.' }
$html = [IO.File]::ReadAllText($index)
if ($html.Contains('cep.zh-cn.js')) { throw 'Chinese patch is already installed. Uninstall before reinstalling.' }
if ((Test-Path -LiteralPath $backup) -and !(Test-Path -LiteralPath $statePath)) { throw 'Incomplete backup found. Inspect it before retrying.' }
foreach ($name in $files) { if (Test-Path -LiteralPath (Join-Path $target $name)) { throw "Existing patch file: $name. No files changed." } }
$scriptTag = '<script src="cep.js"></script>'
if ([regex]::Matches($html,[regex]::Escape($scriptTag)).Count -ne 1) { throw 'Unexpected index.html entry point. No files changed.' }
$js = [IO.File]::ReadAllText($bundle)
foreach ($edit in $spec.edits) {
    $count = [regex]::Matches($js,[regex]::Escape([string]$edit.from)).Count
    if ($count -ne $edit.count) { throw 'Hook count mismatch. No files changed.' }
    $js = $js.Replace([string]$edit.from,[string]$edit.to)
}
$replacement = '<link rel="stylesheet" href="boombox-zh-cn.css"><script src="boombox-zh-cn.dictionary.js"></script><script src="boombox-zh-cn.js"></script><script src="cep.zh-cn.js"></script>'
$newHtml = $html.Replace($scriptTag,$replacement)
$originalBytes = [IO.File]::ReadAllBytes($index)
if (!(Test-Path -LiteralPath $backup)) { New-Item -ItemType Directory -Path $backup | Out-Null }
$originalBackup = Join-Path $backup 'index.html'
if (Test-Path -LiteralPath $originalBackup) {
    if ((Get-Hash $originalBackup) -ne (Get-Hash $index)) { throw 'Existing backup differs from current index. No files changed.' }
} else { [IO.File]::WriteAllBytes($originalBackup,$originalBytes) }
$created = @()
try {
    foreach ($name in $files) {
        $dest = Join-Path $target $name
        if ($name -eq 'cep.zh-cn.js') { Write-Utf8 $dest $js }
        else { [IO.File]::WriteAllBytes($dest,[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $name))) }
        $created += $dest
    }
    $hashes = @{}
    foreach ($name in $files) { $hashes[$name] = Get-Hash (Join-Path $target $name) }
    $indexSha = [Security.Cryptography.SHA256]::Create()
    try { $newIndexHash = ([BitConverter]::ToString($indexSha.ComputeHash($utf8.GetBytes($newHtml)))).Replace('-','').ToLowerInvariant() } finally { $indexSha.Dispose() }
    $state = @{version=$spec.version;originalBundleHash=$spec.sourceSha256;originalIndexHash=(Get-Hash $originalBackup);installedIndexHash=$newIndexHash;payloadHashes=$hashes}
    Write-Utf8 $statePath ($state | ConvertTo-Json -Depth 5)
    # Publish the new entry point only after all payload files and rollback state exist.
    Write-Utf8 $index $newHtml
    if ((Get-Hash $index) -ne $newIndexHash) { throw 'Entry point checksum mismatch.' }
} catch {
    [IO.File]::WriteAllBytes($index,$originalBytes)
    foreach ($file in $created) { if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file } }
    throw
}
Write-Output "Boombox Chinese patch installed in: $target"
Write-Output 'Original cep.js, audio and database unchanged. Close and reopen Boombox.'
