resource "aws_acm_certificate" "qa_app" {
  domain_name       = local.qa_app_fqdn
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = local.qa_app_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "qa_app" {
  certificate_arn         = aws_acm_certificate.qa_app.arn
  validation_record_fqdns = [for record in aws_route53_record.qa_app_acm_domain_validation : record.fqdn]
}

resource "aws_route53_record" "qa_app_acm_domain_validation" {
  zone_id = data.aws_route53_zone.dps.zone_id

  for_each = {
    for dvo in aws_acm_certificate.qa_app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}
