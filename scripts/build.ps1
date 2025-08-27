Write-Host "Building Siege Game backend..." -ForegroundColor Green

$BuildDir = "./build"
$BinaryName = "siege-server.exe"

if (!(Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir
}

$Version = git describe --tags --always --dirty 2>$null
if (!$Version) { $Version = "dev" }
$BuildTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

go build -ldflags "-X main.Version=$Version -X main.BuildTime=$BuildTime" -o "$BuildDir/$BinaryName" ./cmd/server

Write-Host "Build complete: $BuildDir/$BinaryName" -ForegroundColor Green