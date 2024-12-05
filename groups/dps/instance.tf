resource "aws_placement_group" "dps" {
  name     = local.common_resource_name
  strategy = "spread"
}

resource "aws_key_pair" "master" {
  key_name   = "${local.common_resource_name}-master"
  public_key = var.ssh_master_public_key
}

resource "aws_security_group" "common" {
  name   = "common-${local.common_resource_name}"
  vpc_id = data.aws_vpc.heritage.id

  tags = merge(local.common_tags, {
    Name = "common-${local.common_resource_name}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ci_deployments" {
  security_group_id = aws_security_group.common.id
  description       = "Allow inbound SSH connectivity for CI application deployments"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.shared_services_management.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_chips_db_batch" {
  for_each = toset(data.aws_subnet.application[*].cidr_block)

  security_group_id = aws_security_group.common.id
  description       = "Allow inbound SSH connectivity from chips-db-batch instances for QIA checking process"
  cidr_ipv4         = each.key
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "informix_ingress" {
  for_each = {
    for rule in local.informix_hdr_security_group_rules : "${rule.service}-${rule.port}-${rule.cidr_ipv4}" => rule
  }

  security_group_id = aws_security_group.common.id
  description       = "Allow inbound connectivity from ${upper(each.value.service)} Informix databases to ${upper(each.value.service)} Informix databases for cross-instance HDR functionality"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_dps_on_prem" {
  for_each = var.informix_services

  security_group_id = aws_security_group.common.id
  description       = "Allow inbound connectivity from on-premise DPS services to ${upper(each.key)} Informix database for cloud migration"
  cidr_ipv4         = "172.24.4.0/24"
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_alb" {
  security_group_id = aws_security_group.common.id
  description       = "Allow inbound connectivity from QA web application load balancer"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  referenced_security_group_id = aws_security_group.qa_app.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_backend_scanning_samba" {
  for_each = toset(var.backend_scanning_subnets)

  security_group_id = aws_security_group.common.id
  description       = "Allow inbound Samba connectivity for backend scanning share"
  cidr_ipv4         = each.value
  from_port         = 445
  to_port           = 445
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_backend_scanning_ssh" {
  for_each = toset(var.backend_scanning_subnets)

  security_group_id = aws_security_group.common.id
  description       = "Allow inbound SSH connectivity for backend scanning systems to operate workflow process"
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.common.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "dps" {
  count = var.instance_count

  ami             = data.aws_ami.dps.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.master.id
  placement_group = aws_placement_group.dps.id
  subnet_id       = element(local.application_subnet_ids_by_az, count.index) # use 'element' function for wrap-around behaviour

  iam_instance_profile   = module.instance_profile.aws_iam_instance_profile.name
  user_data_base64       = data.cloudinit_config.config[count.index].rendered
  vpc_security_group_ids = [aws_security_group.common.id]

  dynamic "ebs_block_device" {
    for_each = [
      for block_device in data.aws_ami.dps.block_device_mappings :
      block_device if block_device.device_name != data.aws_ami.dps.root_device_name
    ]
    iterator = block_device
    content {
      device_name = block_device.value.device_name
      encrypted   = block_device.value.ebs.encrypted
      iops        = block_device.value.ebs.iops
      snapshot_id = block_device.value.ebs.snapshot_id
      volume_size = var.lvm_block_devices[index(var.lvm_block_devices.*.lvm_physical_volume_device_node, block_device.value.device_name)].aws_volume_size_gb
      volume_type = block_device.value.ebs.volume_type
    }
  }

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = merge(local.common_tags, {
    Name = "${var.service}-${var.environment}-${count.index + 1}"
  })
  volume_tags = local.common_tags
}
