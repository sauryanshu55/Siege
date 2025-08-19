#!/bin/bash

# Siege Game - Local Development Environment Setup Script
# This script sets up and tests the local development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker status..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    directories=(
        "init-scripts"
        "backend"
        "frontend" 
        "docs"
        "scripts"
        "configs"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
    
    print_success "Directory structure created"
}

# Function to copy environment file
setup_env() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.development" ]; then
            cp .env.development .env
            print_success "Environment file created from .env.development"
        else
            print_warning ".env.development not found. Please create .env manually using .env.template"
        fi
    else
        print_status ".env file already exists"
    fi
}

# Function to start Docker services
start_services() {
    print_status "Starting Docker services..."
    
    # Stop any existing containers
    docker-compose down >/dev/null 2>&1 || true
    
    # Start the services
    docker-compose up -d postgres redis
    
    print_success "Docker services started"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL..."
    until docker-compose exec -T postgres pg_isready -U siege_user -d siege_game >/dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    print_success "PostgreSQL is ready"
    
    # Wait for Redis
    print_status "Waiting for Redis..."
    until docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    print_success "Redis is ready"
}

# Function to test database connectivity
test_database() {
    print_status "Testing database connectivity..."
    
    # Test basic connection
    if docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT version();" >/dev/null 2>&1; then
        print_success "Database connection test passed"
    else
        print_error "Database connection test failed"
        return 1
    fi
    
    # Test table creation
    if docker-compose exec -T postgres psql -U siege_user -d siege_game -c "SELECT COUNT(*) FROM players;" >/dev/null 2>&1; then
        print_success "Database schema test passed"
    else
        print_error "Database schema test failed"
        return 1
    fi
}

# Function to test Redis connectivity
test_redis() {
    print_status "Testing Redis connectivity..."
    
    # Test basic connection
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        print_success "Redis connection test passed"
    else
        print_error "Redis connection test failed"
        return 1
    fi
    
    # Test set/get operations
    docker-compose exec -T redis redis-cli set test_key "test_value" >/dev/null
    if docker-compose exec -T redis redis-cli get test_key | grep -q "test_value"; then
        print_success "Redis operations test passed"
        docker-compose exec -T redis redis-cli del test_key >/dev/null
    else
        print_error "Redis operations test failed"
        return 1
    fi
}

# Function to display service information
display_info() {
    print_success "Local development environment is ready!"
    echo ""
    echo "Service Information:"
    echo "==================="
    echo "PostgreSQL:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: siege_game"
    echo "  Username: siege_user"
    echo "  Password: siege_password"
    echo ""
    echo "Redis:"
    echo "  Host: localhost"
    echo "  Port: 6379"
    echo "  No password required"
    echo ""
    echo "Optional GUI Tools (use --profile tools):"
    echo "  pgAdmin: http://localhost:8080 (admin@siege.local / admin123)"
    echo "  Redis Commander: http://localhost:8081"
    echo ""
    echo "Connection Strings:"
    echo "==================="
    echo "PostgreSQL: postgres://siege_user:siege_password@localhost:5432/siege_game?sslmode=disable"
    echo "Redis: redis://localhost:6379/0"
    echo ""
    echo "Useful Commands:"
    echo "================"
    echo "View logs: docker-compose logs -f [postgres|redis]"
    echo "Stop services: docker-compose down"
    echo "Start with GUI tools: docker-compose --profile tools up -d"
    echo "Reset data: docker-compose down -v && docker-compose up -d"
}

# Function to show help
show_help() {
    echo "Siege Game - Local Development Environment Setup"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --with-tools   Start additional GUI tools (pgAdmin, Redis Commander)"
    echo "  --reset        Reset all data and restart services"
    echo "  --stop         Stop all services"
    echo "  --status       Show status of services"
    echo ""
}

# Function to show status
show_status() {
    print_status "Checking service status..."
    echo ""
    docker-compose ps
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    docker-compose down
    print_success "Services stopped"
}

# Function to reset environment
reset_environment() {
    print_status "Resetting environment (this will delete all data)..."
    docker-compose down -v
    docker system prune -f >/dev/null 2>&1 || true
    print_success "Environment reset complete"
    
    # Restart services
    start_services
    wait_for_services
    test_database
    test_redis
    display_info
}

# Main execution
main() {
    echo "Siege Game - Local Development Environment Setup"
    echo "==============================================="
    echo ""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --with-tools)
                WITH_TOOLS=true
                shift
                ;;
            --reset)
                reset_environment
                exit 0
                ;;
            --stop)
                stop_services
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Main setup process
    check_docker
    create_directories
    setup_env
    start_services
    
    # Start additional tools if requested
    if [ "$WITH_TOOLS" = true ]; then
        print_status "Starting additional GUI tools..."
        docker-compose --profile tools up -d
    fi
    
    wait_for_services
    test_database
    test_redis
    display_info
}

# Run main function with all arguments
main "$@"