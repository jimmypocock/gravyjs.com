#!/bin/bash

# Debug CloudFront and S3 configuration
set -e

DISTRIBUTION_ID="E1CEY316OPBGIG"
BUCKET_NAME="gravyjs.com"

# Try to load AWS configuration from parent
if [ -f "$(dirname "$0")/../../../scripts/config.sh" ]; then
    source "$(dirname "$0")/../../../scripts/config.sh"
else
    # Fallback to environment variables
    AWS_REGION=${AWS_REGION:-"us-east-1"}
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Debugging GravyJS Demo Configuration${NC}"
echo ""

# Check S3 bucket
echo -e "${BLUE}1. S3 Bucket Status:${NC}"
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>&1 && echo -e "${GREEN}✅ Bucket exists${NC}" || echo -e "${RED}❌ Bucket not found${NC}"

# Check website configuration
echo -e "\n${BLUE}2. S3 Website Configuration:${NC}"
aws s3api get-bucket-website --bucket "$BUCKET_NAME" 2>/dev/null || echo -e "${RED}❌ No website configuration${NC}"

# Check bucket policy
echo -e "\n${BLUE}3. S3 Bucket Policy:${NC}"
aws s3api get-bucket-policy --bucket "$BUCKET_NAME" --query Policy --output text 2>/dev/null | jq . || echo -e "${RED}❌ No bucket policy${NC}"

# Check public access block
echo -e "\n${BLUE}4. S3 Public Access Block:${NC}"
aws s3api get-public-access-block --bucket "$BUCKET_NAME" 2>/dev/null || echo -e "${YELLOW}⚠️  No public access block (this is OK)${NC}"

# Check CloudFront origin
echo -e "\n${BLUE}5. CloudFront Origin Configuration:${NC}"
aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query 'Distribution.DistributionConfig.Origins.Items[0]' 2>/dev/null | jq . || echo -e "${RED}❌ Could not get distribution${NC}"

# Check if files exist in S3
echo -e "\n${BLUE}6. Files in S3 Bucket:${NC}"
aws s3 ls "s3://$BUCKET_NAME/" --recursive | head -10 || echo -e "${RED}❌ Could not list files${NC}"

# Test S3 website endpoint directly
echo -e "\n${BLUE}7. Testing S3 Website Endpoint:${NC}"
S3_WEBSITE_URL="http://$BUCKET_NAME.s3-website-${AWS_REGION:-us-east-1}.amazonaws.com"
echo "URL: $S3_WEBSITE_URL"
curl -I "$S3_WEBSITE_URL" 2>/dev/null | head -5 || echo -e "${RED}❌ Could not reach S3 website${NC}"

# Check CloudFront status
echo -e "\n${BLUE}8. CloudFront Distribution Status:${NC}"
aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query 'Distribution.[Status,DistributionConfig.Enabled]' --output text 2>/dev/null || echo -e "${RED}❌ Could not get status${NC}"

echo -e "\n${BLUE}📋 Summary:${NC}"
echo "- S3 Bucket: $BUCKET_NAME"
echo "- S3 Website: $S3_WEBSITE_URL"
echo "- CloudFront ID: $DISTRIBUTION_ID"
echo "- CloudFront Domain: https://www.gravyjs.com"