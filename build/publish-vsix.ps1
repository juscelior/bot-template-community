$PersonalAccessToken = $args[0]
$VsixPath = "$PSScriptRoot\..\src\Bot.Template.Community\bin\Release\Bot.Template.Community.vsix"
$ManifestPath = "$PSScriptRoot\extension-manifest.json"

$Installation = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -format json | ConvertFrom-Json
$Path = $Installation.installationPath

Write-Host $Path
$VsixPublisher = Join-Path -Path $Path -ChildPath "VSSDK\VisualStudioIntegration\Tools\Bin\VsixPublisher.exe" -Resolve

Write-Host $VsixPublisher
Test-Path $VsixPublisher

& $VsixPublisher publish -payload $VsixPath -publishManifest $ManifestPath -personalAccessToken $PersonalAccessToken -ignoreWarnings "VSIXValidatorWarning01,VSIXValidatorWarning02,VSIXValidatorWarning08"