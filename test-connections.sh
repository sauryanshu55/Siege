#!/bin/bash

# Simple connection testing script for Siege Game local environment
# This script can be run anytime to verify services are working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test PostgreSQL
test_postgres() {
    print_test "Testing PostgreSQL connection..."
    
    if docker-compose exec -T postgres pg_isready -U siege_user -d siege_game >/dev/null 2>&1; then
        print_pass "PostgreSQL is responding"
    else
        print_fail "PostgreSQL is not responding"
        return 1
    fi
    
    # Test query execution
    if docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT COUNT(*) FROM players;" >/dev/null 2>&1; then
        print_pass "PostgreSQL queries working"
    else
        print_fail "PostgreSQL queries not working"
        return 1
    fi
}

# Test Redis
test_redis() {
    print_test "Testing Redis connection..."
    
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        print_pass "Redis is responding"
    else
        print_fail "Redis is not responding"
        return 1
    fi
    
    # Test Redis operations
    docker-compose exec -T redis redis-cli set test_connection "working" >/dev/null
    if docker-compose exec -T redis redis-cli get test_connection | grep -q "working"; then
        print_pass "Redis operations working"
        docker-compose exec -T redis redis-cli del test_connection >/dev/null
    else
        print_fail "Redis operations not working"
        return 1
    fi
}

# Test network connectivity between services
test_network() {
    print_test "Testing internal network connectivity..."
    
    # Test if Redis is reachable from PostgreSQL container
    if docker-compose exec -T postgres ping -c 1 redis >/dev/null 2>&1; then
        print_pass "Internal network connectivity working"
    else
        print_fail "Internal network connectivity not working"
        return 1
    fi
}

# Check Docker Compose status
check_status() {
    print_test "Checking Docker Compose status..."
    echo ""
    docker-compose ps
    echo ""
}

# Main test execution
main() {
    echo "Siege Game - Connection Tests"
    echo "============================"
    echo ""
    
    check_status
    
    # Run all tests
    local test_results=()
    
    if test_postgres; then
        test_results+=("postgres:pass")
    else
        test_results+=("postgres:fail")
    fi
    
    if test_redis; then
        test_results+=("redis:pass")
    else
        test_results+=("redis:fail")
    fi
    
    if test_network; then
        test_results+=("network:pass")
    else
        test_results+=("network:fail")
    fi
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "============="
    
    local all_passed=true
    for result in "${test_results[@]}"; do
        service=$(echo $result | cut -d: -f1)
        status=$(echo $result | cut -d: -f2)
        
        if [ "$status" = "pass" ]; then
            print_pass "$service tests passed"
        else
            print_fail "$service tests failed"
            all_passed=false
        fi
    done
    
    echo ""
    if [ "$all_passed" = true ]; then
        print_pass "All tests passed! Environment is ready for development."
        exit 0
    else
        print_fail "Some tests failed. Check service configuration."
        exit 1
    fi
}

main "$@"