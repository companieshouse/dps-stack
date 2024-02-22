resource "aws_route53_record" "instance" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.dps.zone_id
  name    = "instance-${count.index + 1}.${var.service}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.dps[count.index].private_ip]
}
