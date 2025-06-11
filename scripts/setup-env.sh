#!/bin/bash

# Setup environment variables for GravyJS Demo
# Usage: ./scripts/setup-env.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")/.."

echo -e "${BLUE}🔧 Setting up environment for GravyJS Demo...${NC}"

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Setup cancelled${NC}"
        exit 1
    fi
fi

# Copy from example if it exists
if [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ Created .env from .env.example${NC}"
else
    # Create a new .env file
    cat > .env << EOF
# Google Analytics
VITE_GA_MEASUREMENT_ID=G-XXXXXXXXXX
EOF
    echo -e "${GREEN}✅ Created new .env file${NC}"
fi

echo -e "${YELLOW}⚡ Next steps:${NC}"
echo -e "1. Edit .env and add your Google Analytics ID"
echo -e "2. Run 'npm run dev' to test locally"
echo -e "3. Run 'npm run deploy' to deploy with the configured Analytics ID"
echo
echo -e "${BLUE}ℹ️  Note: The .env file is gitignored and won't be committed${NC}"