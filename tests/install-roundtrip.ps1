param(
    [Parameter(Mandatory=$true)][string]$OriginalExtension,
    [string]$LegacyPatchPath
)
$ErrorActionPreference='Stop'
function Get-Hash([string]$Path) {
    $sha=[Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Assert-True([bool]$Condition,[string]$Message) { if (!$Condition) { throw $Message } }
$release=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tempParent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$testRoot=Join-Path $tempParent ('boombox-zh-test-'+[Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
foreach($name in @('cep.js','index.html')) { [IO.File]::Copy((Join-Path $OriginalExtension $name),(Join-Path $testRoot $name)) }
function Invoke-Installer([string]$Package,[string]$File,[string]$Mode,[bool]$ExpectedSuccess=$true) {
    $script=Join-Path $Package $File
    $savedPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        if ($Mode) { $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Mode $Mode -ExtensionPath $testRoot 2>&1 }
        else { $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -ExtensionPath $testRoot 2>&1 }
        $result=$LASTEXITCODE
    } finally { $ErrorActionPreference=$savedPreference }
    if (($result -eq 0) -ne $ExpectedSuccess) { throw "$File $Mode failed: $output" }
}
$originalIndex=Get-Hash (Join-Path $testRoot 'index.html')
$originalBundle=Get-Hash (Join-Path $testRoot 'cep.js')
if($LegacyPatchPath) {
    Invoke-Installer $LegacyPatchPath 'patch.ps1' 'Install'
    Invoke-Installer $release 'update.ps1' ''
    Invoke-Installer $release 'update.ps1' ''
} else {
    Invoke-Installer $release 'patch.ps1' 'Install'
    Invoke-Installer $release 'patch.ps1' 'Install' $false
}
$state=[IO.File]::ReadAllText((Join-Path $testRoot 'boombox-zh-cn-backup-v1\state.json')) | ConvertFrom-Json
Assert-True ($state.version -eq '1.0.0') 'Installed version mismatch.'
foreach($name in @('boombox-zh-cn.dictionary.js','boombox-zh-cn.js')) {
    Assert-True ((Get-Hash (Join-Path $testRoot $name)) -eq (Get-Hash (Join-Path $release $name))) "Wrong installed payload: $name"
}
$dictionary=Join-Path $testRoot 'boombox-zh-cn.dictionary.js'
$dictionaryBytes=[IO.File]::ReadAllBytes($dictionary)
[IO.File]::AppendAllText($dictionary,"`n// local modification`n")
Invoke-Installer $release 'patch.ps1' 'Uninstall' $false
[IO.File]::WriteAllBytes($dictionary,$dictionaryBytes)
Invoke-Installer $release 'patch.ps1' 'Uninstall'
Assert-True ((Get-Hash (Join-Path $testRoot 'index.html')) -eq $originalIndex) 'Original index not restored byte-for-byte.'
Assert-True ((Get-Hash (Join-Path $testRoot 'cep.js')) -eq $originalBundle) 'Original bundle changed.'
Assert-True (!(Test-Path -LiteralPath (Join-Path $testRoot 'cep.zh-cn.js'))) 'Generated bundle still present.'
# Recursive cleanup is limited to the exact isolated directory created above.
$resolved=[IO.Path]::GetFullPath((Resolve-Path -LiteralPath $testRoot).Path)
Assert-True ($resolved.StartsWith($tempParent+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe cleanup path.'
Assert-True ([IO.Path]::GetFileName($resolved) -match '^boombox-zh-test-[a-f0-9]{32}$') 'Unsafe cleanup name.'
Write-Output "Verified isolated cleanup target: $resolved"
Remove-Item -LiteralPath $resolved -Recurse -Force
Write-Output 'PASS: installation/upgrade, repeat protection, modified file protection, uninstall and byte-exact original restore.'
