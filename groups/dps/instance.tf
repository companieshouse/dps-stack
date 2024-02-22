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

resource "aws_security_group_rule" "ingress_ci_deployments" {
  type              = "ingress"
  description       = "Allow inbound SSH connectivity for CI application deployments"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.shared_services_management.id]
  security_group_id = aws_security_group.common.id
}

resource "aws_security_group_rule" "ingress_informix_hdr" {
  for_each = var.informix_services

  type              = "ingress"
  description       = "Allow inbound connectivity from ${upper(each.key)} Informix databases to ${upper(each.key)} Informix databases for cross-instance HDR functionality"
  from_port         = each.value
  to_port           = each.value
  protocol          = "TCP"
  cidr_blocks       = data.aws_subnet.application[*].cidr_block
  security_group_id = aws_security_group.common.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
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
