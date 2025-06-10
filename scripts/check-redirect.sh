#!/bin/bash

# Check redirect configuration
DISTRIBUTION_ID="E1CEY316OPBGIG"

# Try to load AWS configuration from parent
if [ -f "$(dirname "$0")/../../../scripts/config.sh" ]; then
    source "$(dirname "$0")/../../../scripts/config.sh"
else
    AWS_REGION=${AWS_REGION:-"us-east-1"}
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Checking redirect configuration...${NC}"

# Check CloudFront function associations
echo -e "\n${BLUE}CloudFront Function Associations:${NC}"
aws cloudfront get-distribution --id "$DISTRIBUTION_ID" \
    --query 'Distribution.DistributionConfig.DefaultCacheBehavior.FunctionAssociations' \
    --output json | jq .

# Check aliases
echo -e "\n${BLUE}CloudFront Aliases:${NC}"
aws cloudfront get-distribution --id "$DISTRIBUTION_ID" \
    --query 'Distribution.DistributionConfig.Aliases.Items' \
    --output json | jq .

# Test redirect with curl
echo -e "\n${BLUE}Testing redirect from gravyjs.com:${NC}"
curl -I -s https://gravyjs.com | head -10

echo -e "\n${BLUE}Testing www.gravyjs.com:${NC}"
curl -I -s https://www.gravyjs.com | head -10

# Check Route 53 records
echo -e "\n${BLUE}📋 Route 53 Configuration Needed:${NC}"
echo "Make sure you have both A records pointing to CloudFront:"
echo "1. gravyjs.com → CloudFront distribution"
echo "2. www.gravyjs.com → CloudFront distribution"