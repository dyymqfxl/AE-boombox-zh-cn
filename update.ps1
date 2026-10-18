param([string]$ExtensionPath = "${env:ProgramFiles(x86)}\Common Files\Adobe\CEP\extensions\com.mtmograph.boombox")
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Get-Hash([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
$target = (Resolve-Path -LiteralPath $ExtensionPath).Path
$backup = Join-Path $target 'boombox-zh-cn-backup-v1'
$statePath = Join-Path $backup 'state.json'
if (!(Test-Path -LiteralPath $statePath)) { throw 'No installed Chinese patch found. Use install.cmd for a fresh installation.' }
$oldStateBytes = [IO.File]::ReadAllBytes($statePath)
$state = [IO.File]::ReadAllText($statePath) | ConvertFrom-Json
$spec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'patch-spec.json')) | ConvertFrom-Json
if ((Get-Hash (Join-Path $target 'cep.js')) -ne $spec.sourceSha256) { throw 'Original Boombox version changed. Refusing update.' }
if ((Get-Hash (Join-Path $target 'index.html')) -ne $state.installedIndexHash) { throw 'Installed entry point changed. Refusing update.' }
if ((Get-Hash (Join-Path $backup 'index.html')) -ne $state.originalIndexHash) { throw 'Original entry point backup checksum mismatch.' }
foreach ($name in @('boombox-zh-cn.dictionary.js','boombox-zh-cn.js','boombox-zh-cn.css','cep.zh-cn.js')) {
    $file = Join-Path $target $name
    if (!(Test-Path -LiteralPath $file) -or (Get-Hash $file) -ne $state.payloadHashes.$name) { throw "Installed patch file changed: $name" }
}
$files = @('boombox-zh-cn.dictionary.js','boombox-zh-cn.js')
if ($state.version -eq $spec.version) {
    $same = $true
    foreach ($name in $files) { if ((Get-Hash (Join-Path $target $name)) -ne (Get-Hash (Join-Path $PSScriptRoot $name))) { $same = $false } }
    if ($same) { Write-Output 'Full Chinese names update is already installed.'; exit 0 }
    throw 'A different build with this version is installed. Refusing to overwrite it.'
}
if ($state.version -notin @('0.1.0','0.2.0')) { throw 'This updater supports patch versions 0.1.0 and 0.2.0 only.' }
$originals = @{}
foreach ($name in $files) {
    $originals[$name] = [IO.File]::ReadAllBytes((Join-Path $target $name))
    $saved = Join-Path $backup ("before-1.0.0-" + $name)
    if (Test-Path -LiteralPath $saved) {
        if ((Get-Hash $saved) -ne $state.payloadHashes.$name) { throw 'Existing update backup differs. Refusing update.' }
    } else { [IO.File]::WriteAllBytes($saved,$originals[$name]) }
}
try {
    foreach ($name in $files) {
        [IO.File]::WriteAllBytes((Join-Path $target $name),[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $name)))
        $state.payloadHashes.$name = Get-Hash (Join-Path $target $name)
    }
    $state.version = $spec.version
    [IO.File]::WriteAllText($statePath,($state | ConvertTo-Json -Depth 5),$utf8)
} catch {
    foreach ($name in $files) { [IO.File]::WriteAllBytes((Join-Path $target $name),$originals[$name]) }
    [IO.File]::WriteAllBytes($statePath,$oldStateBytes)
    throw
}
Write-Output 'Updated: all 3950 built-in sound names now include Chinese. Close and reopen Boombox.'
Write-Output 'Audio, original program and user database unchanged. uninstall.cmd still restores the original extension.'
