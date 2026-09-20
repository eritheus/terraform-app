# Fase 0 (#34 wiring + gap do roadmap): instancia o modulo ALB e aponta o
# dominio do app para ele. Nenhuma sub-issue cobre explicitamente o registro
# DNS do ALB, mas o Definition of Done da Fase 0 exige acesso via
# https://<dominio> - sem esse alias A record o dominio nunca resolveria
# pro ALB.
module "alb" {
  source = "git::https://github.com/eritheus/terraform-modules.git//alb?ref=main"

  name               = "${var.env_name}-customer-registration"
  vpc_id             = aws_vpc.app_vpc.id
  public_subnet_ids  = aws_subnet.public[*].id
  security_group_ids = [aws_security_group.alb.id]
  certificate_arn    = aws_acm_certificate_validation.app.certificate_arn
  target_port        = 8080
  health_check_path  = "/health"

  depends_on = [aws_route_table_association.public]
}

resource "aws_route53_record" "app" {
  zone_id = local.cert_zone_id
  name    = local.app_domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
