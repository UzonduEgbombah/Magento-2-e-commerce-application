#!/bin/bash

# Initialize Terraform
cd terraform
terraform init
terraform apply -auto-approve

# Get outputs
CONTAINER_URL=$(terraform output -raw container_service_url)
DB_ENDPOINT=$(terraform output -raw database_endpoint)
MEDIA_BUCKET=$(terraform output -raw media_bucket_name)

# Build and push Docker image
cd ..
docker build -t magento2-app:latest -f docker/Dockerfile .
aws lightsail push-container-image \
  --service-name magento2-app \
  --label magento2-app \
  --image-name magento2-app:latest

# Deploy container
aws lightsail create-container-service-deployment \
  --service-name magento2-app \
  --containers '{"magento2-app":{"image":"magento2-app:latest","ports":{"80":"HTTP"}}}' \
  --public-endpoint '{"containerName":"magento2-app","containerPort":80}'

echo "Deployment complete!"
echo "Application URL: $CONTAINER_URL"
echo "Database Endpoint: $DB_ENDPOINT"
echo "Media Bucket: $MEDIA_BUCKET"