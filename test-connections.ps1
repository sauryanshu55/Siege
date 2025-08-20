# Simple connection testing script for Siege Game local environment (PowerShell)
# This script can be run anytime to verify services are working

# Function to print colored output
function Write-Test {
    param([string]$Message)
    Write-Host "[TEST] $Message" -ForegroundColor Blue
}

function Write-Pass {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

# Test PostgreSQL
function Test-PostgreSQL {
    Write-Test "Testing PostgreSQL connection..."
    
    docker-compose exec -T postgres pg_isready -U siege_user -d siege_game 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "PostgreSQL is responding"
    }
    else {
        Write-Fail "PostgreSQL is not responding"
        return $false
    }
    
    # Test query execution
    docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT COUNT(*) FROM players;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "PostgreSQL queries working"
    }
    else {
        Write-Fail "PostgreSQL queries not working"
        return $false
    }
    
    return $true
}

# Test Redis
function Test-RedisConnection {
    Write-Test "Testing Redis connection..."
    
    $pingResult = docker-compose exec -T redis redis-cli ping 2>$null
    if ($pingResult -match "PONG") {
        Write-Pass "Redis is responding"
    }
    else {
        Write-Fail "Redis is not responding"
        return $false
    }
    
    # Test Redis operations
    docker-compose exec -T redis redis-cli set test_connection "working" 2>$null | Out-Null
    $getValue = docker-compose exec -T redis redis-cli get test_connection 2>$null
    if ($getValue -match "working") {
        Write-Pass "Redis operations working"
        docker-compose exec -T redis redis-cli del test_connection 2>$null | Out-Null
    }
    else {
        Write-Fail "Redis operations not working"
        return $false
    }
    
    return $true
}

# Test network connectivity between services
function Test-NetworkConnectivity {
    Write-Test "Testing internal network connectivity..."
    
    # Test if Redis is reachable from PostgreSQL container
    docker-compose exec -T postgres ping -c 1 redis 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Internal network connectivity working"
        return $true
    }
    else {
        Write-Fail "Internal network connectivity not working"
        return $false
    }
}

# Check Docker Compose status
function Show-Status {
    Write-Test "Checking Docker Compose status..."
    Write-Host ""
    docker-compose ps
    Write-Host ""
}

# Main test execution
function Main {
    Write-Host "Siege Game - Connection Tests" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    
    Show-Status
    
    # Run all tests
    $testResults = @()
    
    if (Test-PostgreSQL) {
        $testResults += "postgres:pass"
    }
    else {
        $testResults += "postgres:fail"
    }
    
    if (Test-RedisConnection) {
        $testResults += "redis:pass"
    }
    else {
        $testResults += "redis:fail"
    }
    
    if (Test-NetworkConnectivity) {
        $testResults += "network:pass"
    }
    else {
        $testResults += "network:fail"
    }
    
    # Summary
    Write-Host ""
    Write-Host "Test Summary:" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    
    $allPassed = $true
    foreach ($result in $testResults) {
        $parts = $result -split ":"
        $service = $parts[0]
        $status = $parts[1]
        
        if ($status -eq "pass") {
            Write-Pass "$service tests passed"
        }
        else {
            Write-Fail "$service tests failed"
            $allPassed = $false
        }
    }
    
    Write-Host ""
    if ($allPassed) {
        Write-Pass "All tests passed! Environment is ready for development."
        exit 0
    }
    else {
        Write-Fail "Some tests failed. Check service configuration."
        exit 1
    }
}

# Run main function
Main