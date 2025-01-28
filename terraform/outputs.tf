output "container_service_url" {
  description = "URL of the Lightsail container service"
  value       = aws_lightsail_container_service.magento.url
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_lightsail_database.magento_db.master_endpoint_address
}

output "media_bucket_name" {
  description = "S3 bucket name for media storage"
  value       = aws_s3_bucket.magento_media.id
}