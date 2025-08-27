Write-Host "Starting Siege Game in development mode..." -ForegroundColor Blue

$env:ENVIRONMENT = "development"

if (Get-Command air -ErrorAction SilentlyContinue) {
    Write-Host "Using Air for hot reload..." -ForegroundColor Yellow
    air -c .air.toml
} else {
    Write-Host "Air not found. Install with: go install github.com/cosmtrek/air@latest" -ForegroundColor Yellow
    Write-Host "Running with go run..." -ForegroundColor Yellow
    go run ./cmd/server
}