output "name" {
  description = "Name of the image repository"
  value       = var.name
}

output "repository_url" {
  description = "URL of this container image repository"
  value       = var.create ? aws_ecr_repository.this[0].repository_url : data.aws_ecr_repository.this[0].repository_url
}
