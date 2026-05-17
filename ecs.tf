resource "aws_security_group" "ecs_app" {
  name        = "ecs-app-sg"
  description = "Security group for ECS app services"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-app-sg"
  }
}

module "ecs_cluster" {
  source = "git::https://github.com/eritheus/terraform-modules.git//ecs-cluster?ref=main"
  name   = "registration"
}

module "ecs_app_customer_registration" {
  source             = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name       = module.ecs_cluster.name
  cluster_arn        = module.ecs_cluster.arn
  app_name           = "customer-registration"
  image_name         = "nginx:latest"
  subnet_ids         = aws_subnet.app[*].id
  security_group_ids = [aws_security_group.ecs_app.id]

  depends_on = [module.ecs_cluster]
}

module "ecs_app_product_registration" {
  source             = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name       = module.ecs_cluster.name
  cluster_arn        = module.ecs_cluster.arn
  app_name           = "product-registration"
  image_name         = "nginx:latest"
  subnet_ids         = aws_subnet.app[*].id
  security_group_ids = [aws_security_group.ecs_app.id]

  depends_on = [module.ecs_cluster]
}
