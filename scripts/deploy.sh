#!/bin/bash

# Deploy GravyJS Demo to S3 and CloudFront
# Usage: npm run deploy

set -e  # Exit on error

# Configuration
GRAVYJS_BUCKET="gravyjs.com"
GRAVYJS_DOMAIN="gravyjs.com"
DISTRIBUTION_ID="E1CEY316OPBGIG"

# Try to load AWS configuration from parent
if [ -f "$(dirname "$0")/../../../scripts/config.sh" ]; then
    source "$(dirname "$0")/../../../scripts/config.sh"
else
    # Fallback to environment variables
    AWS_REGION=${AWS_REGION:-"us-east-1"}
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying GravyJS Demo...${NC}"

# Navigate to project root (scripts is in packages/gravyjs-demo/scripts)
cd "$(dirname "$0")/.."

# Build the demo
echo -e "${BLUE}📦 Building GravyJS demo...${NC}"
npm run build

# Check if bucket exists
if ! aws s3api head-bucket --bucket "$GRAVYJS_BUCKET" 2>/dev/null; then
    echo -e "${RED}❌ S3 bucket does not exist. Run 'npm run setup' first${NC}"
    exit 1
fi

# Sync files to S3
echo -e "${BLUE}📤 Uploading files to S3...${NC}"

# Upload static assets with long cache
aws s3 sync dist/ "s3://$GRAVYJS_BUCKET" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html" \
    --exclude "*.js" \
    --exclude "*.css"

# Upload HTML with shorter cache
aws s3 cp dist/index.html "s3://$GRAVYJS_BUCKET/index.html" \
    --cache-control "public, max-age=3600" \
    --content-type "text/html"

# Upload JS and CSS with medium cache
aws s3 sync dist/ "s3://$GRAVYJS_BUCKET" \
    --exclude "*" \
    --include "*.js" \
    --include "*.css" \
    --cache-control "public, max-age=86400"

# Invalidate CloudFront cache
echo -e "${BLUE}🔄 Invalidating CloudFront cache...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${BLUE}🌐 Live at: https://$GRAVYJS_DOMAIN${NC}"
echo -e "${BLUE}📋 Invalidation ID: $INVALIDATION_ID${NC}"