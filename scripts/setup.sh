#!/bin/bash

# Complete setup for GravyJS Demo with S3 + CloudFront using OAC
# This is the ONLY setup script needed
# Usage: npm run setup
#
# RESOURCES CREATED BY THIS SCRIPT:
# =================================
# 1. S3 Bucket: gravyjs.com
#    - Private bucket with CloudFront-only access
#    - Public access block enabled
#    - Bucket policy for OAC access
#
# 2. CloudFront Origin Access Control (OAC): gravyjs-oac
#    - Allows CloudFront to access private S3 bucket
#    - Type: S3
#
# 3. CloudFront Distribution: E1CEY316OPBGIG (existing)
#    - Updates origin to use OAC
#    - Adds aliases: gravyjs.com, www.gravyjs.com
#    - Configured for SPA routing (404 → index.html)
#
# 4. CloudFront Function: gravyjs-www-redirect-{timestamp}
#    - Redirects gravyjs.com → www.gravyjs.com
#    - Handles SPA routing for non-file URLs
#
# TO TEAR DOWN:
# - Delete CloudFront distribution (must disable first)
# - Delete CloudFront function
# - Delete Origin Access Control
# - Empty and delete S3 bucket
# =================================

set -e  # Exit on error

# Configuration
GRAVYJS_BUCKET="gravyjs.com"
GRAVYJS_DOMAIN="gravyjs.com"
GRAVYJS_WWW_DOMAIN="www.gravyjs.com"
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
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up GravyJS Demo infrastructure...${NC}"

# 1. Create S3 bucket if it doesn't exist
if ! aws s3api head-bucket --bucket "$GRAVYJS_BUCKET" 2>/dev/null; then
    echo -e "${BLUE}🪣 Creating S3 bucket: $GRAVYJS_BUCKET${NC}"
    aws s3api create-bucket \
        --bucket "$GRAVYJS_BUCKET" \
        --region "$AWS_REGION" \
        $(if [ "$AWS_REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$AWS_REGION"; fi)
else
    echo -e "${GREEN}✅ S3 bucket already exists${NC}"
fi

# 2. Make bucket private (proper security)
echo -e "${BLUE}🔒 Configuring S3 bucket as private...${NC}"
aws s3api put-public-access-block \
    --bucket "$GRAVYJS_BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Remove any existing public policies
aws s3api delete-bucket-policy --bucket "$GRAVYJS_BUCKET" 2>/dev/null || true

# 3. Create Origin Access Control
echo -e "${BLUE}📝 Setting up Origin Access Control...${NC}"

# Try to find existing OAC first
OAC_ID=$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='gravyjs-oac'].Id | [0]" --output text 2>/dev/null)

if [ -z "$OAC_ID" ] || [ "$OAC_ID" = "None" ]; then
    # Create new OAC
    echo -e "${BLUE}Creating new Origin Access Control...${NC}"
    OAC_RESULT=$(aws cloudfront create-origin-access-control \
        --origin-access-control-config \
        Name="gravyjs-oac",\
Description="OAC for gravyjs.com",\
SigningProtocol="sigv4",\
SigningBehavior="always",\
OriginAccessControlOriginType="s3" 2>&1)
    
    if [ $? -eq 0 ]; then
        OAC_ID=$(echo "$OAC_RESULT" | jq -r '.OriginAccessControl.Id')
    else
        echo -e "${RED}❌ Failed to create OAC: $OAC_RESULT${NC}"
        exit 1
    fi
fi

if [ -z "$OAC_ID" ] || [ "$OAC_ID" = "None" ]; then
    echo -e "${RED}❌ Could not create or find Origin Access Control${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OAC configured: $OAC_ID${NC}"

# 4. Check and update CloudFront distribution
echo -e "${BLUE}🔍 Configuring CloudFront distribution...${NC}"
if aws cloudfront get-distribution --id "$DISTRIBUTION_ID" > /dev/null 2>&1; then
    # Get current config
    aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" > /tmp/current-config.json
    jq '.DistributionConfig' /tmp/current-config.json > /tmp/distribution-config.json
    ETAG=$(jq -r '.ETag' /tmp/current-config.json)
    
    # Update origin to use regular S3 endpoint with OAC
    jq --arg bucket "$GRAVYJS_BUCKET" --arg region "$AWS_REGION" --arg oac "$OAC_ID" '
      .Origins.Items[0] = {
        "Id": "S3-\($bucket)",
        "DomainName": "\($bucket).s3.\($region).amazonaws.com",
        "OriginPath": "",
        "CustomHeaders": {"Quantity": 0},
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "OriginAccessControlId": $oac,
        "ConnectionAttempts": 3,
        "ConnectionTimeout": 10,
        "OriginShield": {"Enabled": false}
      }' /tmp/distribution-config.json > /tmp/updated-config.json
    
    # Add both domains to aliases if not already there
    if ! jq -e '.Aliases.Items | index("www.gravyjs.com")' /tmp/updated-config.json > /dev/null 2>&1; then
        jq '.Aliases.Quantity = 2 | .Aliases.Items = ["gravyjs.com", "www.gravyjs.com"]' \
            /tmp/updated-config.json > /tmp/temp-config.json && mv /tmp/temp-config.json /tmp/updated-config.json
    fi
    
    # Update the distribution
    aws cloudfront update-distribution \
        --id "$DISTRIBUTION_ID" \
        --distribution-config file:///tmp/updated-config.json \
        --if-match "$ETAG" > /dev/null
    
    echo -e "${GREEN}✅ CloudFront configured with OAC${NC}"
    
    # Set up redirect function
    echo -e "${BLUE}🔄 Setting up redirect function...${NC}"
    
    # Check if redirect function already exists
    EXISTING_FUNCTION=$(aws cloudfront list-functions --query "FunctionList.Items[?contains(Name,'gravyjs')].Name | [0]" --output text 2>/dev/null || echo "None")
    
    if [ "$EXISTING_FUNCTION" != "None" ] && [ -n "$EXISTING_FUNCTION" ]; then
        echo -e "${GREEN}✅ Found existing function: $EXISTING_FUNCTION${NC}"
        FUNCTION_ARN=$(aws cloudfront describe-function --name "$EXISTING_FUNCTION" --query 'FunctionSummary.FunctionMetadata.FunctionARN' --output text)
    else
        echo -e "${BLUE}🔄 Creating redirect function...${NC}"
        
        # Create redirect function
        cat > /tmp/redirect-function.js <<'EOF'
function handler(event) {
    var request = event.request;
    var host = request.headers.host && request.headers.host.value ? request.headers.host.value : '';
    var uri = request.uri;
    
    // Redirect non-www to www
    if (host === 'gravyjs.com') {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                location: { value: 'https://www.gravyjs.com' + uri }
            }
        };
    }
    
    // For SPAs: Route all non-file requests to index.html
    if (uri && !uri.includes('.')) {
        request.uri = '/index.html';
    }
    
    return request;
}
EOF
        
        FUNCTION_NAME="gravyjs-www-redirect-$(date +%s)"
        FUNCTION_ARN=$(aws cloudfront create-function \
            --name "$FUNCTION_NAME" \
            --function-config Comment="Redirect gravyjs.com to www.gravyjs.com",Runtime="cloudfront-js-1.0" \
            --function-code fileb:///tmp/redirect-function.js \
            --query 'FunctionSummary.FunctionMetadata.FunctionARN' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$FUNCTION_ARN" ]; then
            # Publish function
            FUNCTION_ETAG=$(aws cloudfront describe-function --name "$FUNCTION_NAME" --query 'ETag' --output text)
            aws cloudfront publish-function --name "$FUNCTION_NAME" --if-match "$FUNCTION_ETAG" > /dev/null
            
            # Attach to distribution
            jq --arg arn "$FUNCTION_ARN" '.DefaultCacheBehavior.FunctionAssociations = {
                "Quantity": 1,
                "Items": [{
                    "FunctionARN": $arn,
                    "EventType": "viewer-request"
                }]
            }' /tmp/distribution-config.json > /tmp/updated-config.json
            
            aws cloudfront update-distribution \
                --id "$DISTRIBUTION_ID" \
                --distribution-config file:///tmp/updated-config.json \
                --if-match "$ETAG" > /dev/null
            
            echo -e "${GREEN}✅ Redirect function created${NC}"
        fi
        rm -f /tmp/redirect-function.js
    fi
    
    # Always check and attach function to distribution
    aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" > /tmp/current-config.json
    jq '.DistributionConfig' /tmp/current-config.json > /tmp/distribution-config.json
    ETAG=$(jq -r '.ETag' /tmp/current-config.json)
    
    # Check if function is attached
    ATTACHED_FUNCTION=$(jq -r '.DefaultCacheBehavior.FunctionAssociations.Quantity // 0' /tmp/distribution-config.json)
    
    if [ "$ATTACHED_FUNCTION" -eq 0 ]; then
        echo -e "${BLUE}🔗 Attaching function to distribution...${NC}"
        
        # Attach function
        jq --arg arn "$FUNCTION_ARN" '.DefaultCacheBehavior.FunctionAssociations = {
            "Quantity": 1,
            "Items": [{
                "FunctionARN": $arn,
                "EventType": "viewer-request"
            }]
        }' /tmp/distribution-config.json > /tmp/updated-config.json
        
        aws cloudfront update-distribution \
            --id "$DISTRIBUTION_ID" \
            --distribution-config file:///tmp/updated-config.json \
            --if-match "$ETAG" > /dev/null
            
        echo -e "${GREEN}✅ Redirect function attached${NC}"
    else
        echo -e "${GREEN}✅ Redirect function already attached${NC}"
    fi
    
    rm -f /tmp/current-config.json /tmp/distribution-config.json /tmp/updated-config.json
else
    echo -e "${YELLOW}⚠️  CloudFront distribution not found${NC}"
    echo -e "${YELLOW}   Please create a CloudFront distribution for gravyjs.com${NC}"
    exit 1
fi

# 5. Set bucket policy for CloudFront OAC access
echo -e "${BLUE}📋 Setting bucket policy for CloudFront access...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cat > /tmp/bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipalReadOnly",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$GRAVYJS_BUCKET/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DISTRIBUTION_ID"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "$GRAVYJS_BUCKET" \
    --policy file:///tmp/bucket-policy.json

rm /tmp/bucket-policy.json

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "${BLUE}   - S3 Bucket: $GRAVYJS_BUCKET (private with OAC)${NC}"
echo -e "${BLUE}   - CloudFront ID: $DISTRIBUTION_ID${NC}"
echo -e "${BLUE}   - Domains: https://$GRAVYJS_DOMAIN → https://$GRAVYJS_WWW_DOMAIN${NC}"
echo -e "${YELLOW}⏳ CloudFront updates take 5-10 minutes to propagate${NC}"