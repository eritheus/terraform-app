# Private mirror of nginx so Fargate tasks in the private app subnets can pull
# the image through the existing ECR/S3 VPC endpoints, avoiding a NAT Gateway
# (~$32/mo per AZ) just to reach Docker Hub.
resource "aws_ecr_repository" "nginx" {
  name         = "${var.env_name}/nginx"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = var.env_name
    Name        = "${var.env_name}-nginx"
  }
}

# Keep only the most recent images to avoid storage piling up in the lab.
resource "aws_ecr_lifecycle_policy" "nginx" {
  repository = aws_ecr_repository.nginx.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 3 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "nginx_repository_url" {
  description = "ECR repository URL for the mirrored nginx image"
  value       = aws_ecr_repository.nginx.repository_url
}
