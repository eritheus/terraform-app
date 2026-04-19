env_name = "prod"
vpc_cidr = "10.2.0.0/16"

availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

public_subnet_cidrs = ["10.2.0.0/22", "10.2.4.0/22", "10.2.8.0/22"]
app_subnet_cidrs    = ["10.2.16.0/22", "10.2.20.0/22", "10.2.24.0/22"]
data_subnet_cidrs   = ["10.2.32.0/22", "10.2.36.0/22", "10.2.40.0/22"]
