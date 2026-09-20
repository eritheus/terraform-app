# Fase 0 (#35): hosted zone Route53 para lowbit.com.br.
#
# A hosted zone apex (lowbit.com.br) NAO e criada por este repo - ela e
# criada manualmente uma unica vez (console ou `aws route53
# create-hosted-zone`) e delegada no registrador do dominio. Isso e de
# proposito: se ela fosse um recurso gerenciado aqui (ou no terraform-shared,
# que e destruido periodicamente), um destroy recriaria a zone com NS
# servers novos e quebraria a delegacao no registrador toda vez. Este repo
# so faz um lookup read-only dela via data source - nunca cria nem destroi.
#
# A subzone dev.lowbit.com.br (workspace dev) e gerenciada aqui e delegada
# dentro da propria zone apex. Se ela for destruida/recriada, a
# re-delegacao e so um registro NS dentro da conta AWS, sem passo manual no
# registrador.
locals {
  is_prod = terraform.workspace == "prod"
}

data "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_zone" "dev" {
  count = local.is_prod ? 0 : 1
  name  = "dev.${var.domain_name}"

  tags = {
    Environment = terraform.workspace
  }
}

resource "aws_route53_record" "dev_delegation" {
  count   = local.is_prod ? 0 : 1
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "dev.${var.domain_name}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.dev[0].name_servers
}
