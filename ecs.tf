
module "ecs_cluster" {
  source = "git::https://github.com/eritheus/terraform-modules.git//ecs-cluster?ref=main"
  name   = "registration"
}

module "ecs_app_customer_registration" {
  source             = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name       = module.ecs_cluster.name
  cluster_arn        = module.ecs_cluster.arn
  app_name           = "customer-registration"
  image_name         = "${aws_ecr_repository.nginx.repository_url}:latest"
  subnet_ids         = aws_subnet.app[*].id
  security_group_ids = [aws_security_group.ecs_app.id]

  depends_on = [module.ecs_cluster]
}

module "ecs_app_product_registration" {
  source             = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name       = module.ecs_cluster.name
  cluster_arn        = module.ecs_cluster.arn
  app_name           = "product-registration"
  image_name         = "${aws_ecr_repository.nginx.repository_url}:latest"
  subnet_ids         = aws_subnet.app[*].id
  security_group_ids = [aws_security_group.ecs_app.id]

  depends_on = [module.ecs_cluster]
}