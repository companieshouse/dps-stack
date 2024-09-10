resource "aws_route53_record" "qa_app" {
  zone_id = data.aws_route53_zone.dps.zone_id
  name    = local.qa_app_dns_name
  type    = "A"

  alias {
    name    = aws_lb.qa_app.dns_name
    zone_id = aws_lb.qa_app.zone_id

    evaluate_target_health = false
  }
}

resource "aws_route53_record" "instance" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.dps.zone_id
  name    = "instance-${count.index + 1}.${var.service}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.dps[count.index].private_ip]
}
