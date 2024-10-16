resource "aws_lb" "qa_app" {
  name               = local.qa_app_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.qa_app.id]
  subnets            = data.aws_subnet.application[*].id

  drop_invalid_header_fields = true

  access_logs {
    bucket  = local.lb_access_logs_bucket_name
    prefix  = local.lb_access_logs_prefix
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = local.qa_app_name
  })
}

resource "aws_security_group" "qa_app" {
  name   = local.qa_app_name
  vpc_id = data.aws_vpc.heritage.id

  tags = merge(local.common_tags, {
    Name = local.qa_app_name
  })
}

resource "aws_security_group_rule" "qa_app_http" {
  type        = "ingress"
  description = "Allow inbound connectivity to QA web application"
  from_port   = 80
  to_port     = 80
  protocol    = "TCP"
  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.vpn.id,
    data.aws_ec2_managed_prefix_list.on_premise.id
  ]
  security_group_id = aws_security_group.qa_app.id
}

resource "aws_security_group_rule" "qa_app_https" {
  type        = "ingress"
  description = "Allow inbound connectivity to QA web application"
  from_port   = 443
  to_port     = 443
  protocol    = "TCP"
  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.vpn.id,
    data.aws_ec2_managed_prefix_list.on_premise.id
  ]
  security_group_id = aws_security_group.qa_app.id
}

resource "aws_security_group_rule" "lb_egress_all" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.qa_app.id
}

resource "aws_lb_listener" "qa_app_http" {
  load_balancer_arn = aws_lb.qa_app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "qa_app_https" {
  load_balancer_arn = aws_lb.qa_app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.companieshouse.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.qa_app.arn
  }
}

resource "aws_lb_target_group" "qa_app" {
  name        = local.qa_app_name
  port        = "8080"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.heritage.id

  health_check {
    interval            = "30"
    protocol            = "HTTP"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = local.qa_app_name
  })
}

resource "aws_lb_target_group_attachment" "qa_app" {
  target_id        = aws_instance.dps[0].id
  target_group_arn = aws_lb_target_group.qa_app.arn
}
