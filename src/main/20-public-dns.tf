module "dn_zone" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.0"

  zones = var.public_dns_zones
}

resource "aws_route53_record" "uat" {
  count           = var.env_short == "p" ? 1 : 0
  allow_overwrite = true
  name            = "uat"
  ttl             = var.dns_record_ttl
  type            = "NS"
  zone_id         = module.dn_zone.route53_zone_zone_id[keys(var.public_dns_zones)[0]]

  records = [
    "ns-1471.awsdns-55.org",
    "ns-90.awsdns-11.com",
    "ns-962.awsdns-56.net",
    "ns-1970.awsdns-54.co.uk",
  ]
}

resource "aws_api_gateway_domain_name" "main" {
  count                    = var.apigw_custom_domain_create ? 1 : 0
  domain_name              = local.apigw_custom_domain
  regional_certificate_arn = aws_acm_certificate.main[0].arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  security_policy = "TLS_1_2"
}

resource "aws_route53_record" "main" {
  count   = var.apigw_custom_domain_create ? 1 : 0
  zone_id = module.dn_zone.route53_zone_zone_id[keys(var.public_dns_zones)[0]]
  name    = aws_api_gateway_domain_name.main[0].domain_name
  type    = "A"
  ttl     = var.dns_record_ttl
  alias {
    name                   = aws_api_gateway_domain_name.main[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main[0].regional_zone_id
    evaluate_target_health = true
  }
}