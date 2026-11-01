env_name = "dev"
vpc_cidr = "10.1.0.0/16"

availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

public_subnet_cidrs = ["10.1.0.0/22", "10.1.4.0/22", "10.1.8.0/22"]
app_subnet_cidrs    = ["10.1.16.0/22", "10.1.20.0/22", "10.1.24.0/22"]
data_subnet_cidrs   = ["10.1.32.0/22", "10.1.36.0/22", "10.1.40.0/22"]

domain_name = "lowbit.com.br"

allowed_cidrs = ["172.225.209.16/32", "187.57.51.124/32", "177.24.4.254/32", "179.209.46.230/32", "104.28.63.119/32"]
