module "ecs_cluster" {
  source = "git::https://github.com/eritheus/terraform-modules.git//ecs-cluster?ref=main"
  name   = "registration"
}

module "ecs_app_customer_registration" {
  source       = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name = module.ecs_cluster.name
  app_name     = "customer-registration"
  image_name   = "nginx:latest"

  depends_on = [module.ecs_cluster]
}

module "ecs_app_product_registration" {
  source       = "git::https://github.com/eritheus/terraform-modules.git//ecs-app?ref=main"
  cluster_name = module.ecs_cluster.name
  app_name     = "product-registration"
  image_name   = "nginx:latest"

  depends_on = [module.ecs_cluster]
}
