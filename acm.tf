# Fase 0 (#36): certificado ACM publico (us-east-2, compativel com ALB) com
# validacao via DNS. prod usa o apex do dominio; dev usa a subzone
# dev.lowbit.com.br. O registro de validacao vai para a zone correspondente
# a cada workspace (apex via data source read-only, subzone dev via o
# recurso gerenciado em dns.tf).
locals {
  app_domain   = local.is_prod ? var.domain_name : "dev.${var.domain_name}"
  cert_zone_id = local.is_prod ? data.aws_route53_zone.primary.zone_id : aws_route53_zone.dev[0].zone_id
}

resource "aws_acm_certificate" "app" {
  domain_name       = local.app_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = terraform.workspace
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = local.cert_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
