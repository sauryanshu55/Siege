# Siege Game - Local Development Environment Setup Script (PowerShell)
# This script sets up and tests the local development environment

param(
    [switch]$WithTools,
    [switch]$Reset,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Help
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if Docker is running
function Test-Docker {
    Write-Status "Checking Docker status..."
    try {
        $null = docker info 2>$null
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop and try again."
        return $false
    }
}

# Function to copy environment file
function Set-Environment {
    Write-Status "Setting up environment configuration..."
    
    if (!(Test-Path ".env")) {
        if (Test-Path ".env.development") {
            Copy-Item ".env.development" ".env"
            Write-Success "Environment file created from .env.development"
        }
        else {
            Write-Warning ".env.development not found. Please create .env manually using .env.template"
        }
    }
    else {
        Write-Status ".env file already exists"
    }
}

# Function to start Docker services
function Start-Services {
    Write-Status "Starting Docker services..."
    
    # Stop any existing containers
    try {
        docker-compose down 2>$null | Out-Null
    }
    catch {
        # Ignore errors if no containers are running
    }
    
    # Start the services
    docker-compose up -d postgres redis
    
    Write-Success "Docker services started"
}

# Function to wait for services to be ready
function Wait-ForServices {
    Write-Status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    Write-Status "Waiting for PostgreSQL..."
    do {
        Write-Host "." -NoNewline
        Start-Sleep 1
        docker-compose exec -T postgres pg_isready -U siege_user -d siege_game 2>$null
    } while ($LASTEXITCODE -ne 0)
    Write-Host ""
    Write-Success "PostgreSQL is ready"
    
    # Wait for Redis
    Write-Status "Waiting for Redis..."
    do {
        Write-Host "." -NoNewline
        Start-Sleep 1
        $redisReady = docker-compose exec -T redis redis-cli ping 2>$null
    } while ($redisReady -notmatch "PONG")
    Write-Host ""
    Write-Success "Redis is ready"
}

# Function to test database connectivity
function Test-Database {
    Write-Status "Testing database connectivity..."
    
    # Test basic connection
    docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT version();" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database connection test passed"
    }
    else {
        Write-Error "Database connection test failed"
        return $false
    }
    
    # Test table creation
    docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT COUNT(*) FROM players;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database schema test passed"
    }
    else {
        Write-Error "Database schema test failed"
        return $false
    }
    
    return $true
}

# Function to test Redis connectivity
function Test-Redis {
    Write-Status "Testing Redis connectivity..."
    
    # Test basic connection
    $pingTest = docker-compose exec -T redis redis-cli ping 2>$null
    if ($pingTest -match "PONG") {
        Write-Success "Redis connection test passed"
    }
    else {
        Write-Error "Redis connection test failed"
        return $false
    }
    
    # Test set/get operations
    docker-compose exec -T redis redis-cli set test_key "test_value" 2>$null | Out-Null
    $getValue = docker-compose exec -T redis redis-cli get test_key 2>$null
    if ($getValue -match "test_value") {
        Write-Success "Redis operations test passed"
        docker-compose exec -T redis redis-cli del test_key 2>$null | Out-Null
    }
    else {
        Write-Error "Redis operations test failed"
        return $false
    }
    
    return $true
}

# Function to display service information
function Show-ServiceInfo {
    Write-Success "Local development environment is ready!"
    Write-Host ""
    Write-Host "Service Information:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "PostgreSQL:"
    Write-Host "  Host: localhost"
    Write-Host "  Port: 5432"
    Write-Host "  Database: siege_game"
    Write-Host "  Username: siege_user"
    Write-Host "  Password: siege_password"
    Write-Host ""
    Write-Host "Redis:"
    Write-Host "  Host: localhost"
    Write-Host "  Port: 6379"
    Write-Host "  No password required"
    Write-Host ""
    Write-Host "Optional GUI Tools (use -WithTools):" -ForegroundColor Yellow
    Write-Host "  pgAdmin: http://localhost:8080 (admin@siege.local / admin123)"
    Write-Host "  Redis Commander: http://localhost:8081"
    Write-Host ""
    Write-Host "Connection Strings:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "PostgreSQL: postgres://siege_user:siege_password@localhost:5432/siege_game?sslmode=disable"
    Write-Host "Redis: redis://localhost:6379/0"
    Write-Host ""
    Write-Host "Useful Commands:" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "View logs: docker-compose logs -f [postgres|redis]"
    Write-Host "Stop services: .\setup-local.ps1 -Stop"
    Write-Host "Start with GUI tools: .\setup-local.ps1 -WithTools"
    Write-Host "Reset data: .\setup-local.ps1 -Reset"
}

# Function to show help
function Show-Help {
    Write-Host "Siege Game - Local Development Environment Setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\setup-local.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help          Show this help message"
    Write-Host "  -WithTools     Start additional GUI tools (pgAdmin, Redis Commander)"
    Write-Host "  -Reset         Reset all data and restart services"
    Write-Host "  -Stop          Stop all services"
    Write-Host "  -Status        Show status of services"
    Write-Host ""
}

# Function to show status
function Show-Status {
    Write-Status "Checking service status..."
    Write-Host ""
    docker-compose ps
}

# Function to stop services
function Stop-Services {
    Write-Status "Stopping all services..."
    docker-compose down
    Write-Success "Services stopped"
}

# Function to reset environment
function Reset-Environment {
    Write-Status "Resetting environment (this will delete all data)..."
    docker-compose down -v
    try {
        docker system prune -f 2>$null | Out-Null
    }
    catch {
        # Ignore errors
    }
    Write-Success "Environment reset complete"
    
    # Restart services
    Start-Services
    Wait-ForServices
    if ((Test-Database) -and (Test-Redis)) {
        Show-ServiceInfo
    }
}

# Main execution
function Main {
    Write-Host "Siege Game - Local Development Environment Setup" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Handle command line parameters
    if ($Help) {
        Show-Help
        return
    }
    
    if ($Status) {
        Show-Status
        return
    }
    
    if ($Stop) {
        Stop-Services
        return
    }
    
    if ($Reset) {
        Reset-Environment
        return
    }
    
    # Main setup process
    if (!(Test-Docker)) {
        return
    }
    
    Set-Environment
    Start-Services
    
    # Start additional tools if requested
    if ($WithTools) {
        Write-Status "Starting additional GUI tools..."
        docker-compose --profile tools up -d
    }
    
    Wait-ForServices
    
    if ((Test-Database) -and (Test-Redis)) {
        Show-ServiceInfo
    }
    else {
        Write-Error "Setup completed but some tests failed. Check the logs above."
    }
}

# Run main function
Main