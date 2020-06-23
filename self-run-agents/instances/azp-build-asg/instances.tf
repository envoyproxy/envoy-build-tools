locals {
  asg_name = "${var.ami_prefix}_${var.azp_pool_name}_build_pool"
}

data "aws_ami" "azp_ci_image" {
  most_recent = true
  owners      = [var.aws_account_id]

  filter {
    name   = "name"
    values = ["${var.ami_prefix}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "init" {
  template = file("${path.module}/init.sh.tpl")
  vars = {
    asg_name      = local.asg_name
    azp_pool_name = var.azp_pool_name
    azp_token     = var.azp_token
  }
}

resource "aws_placement_group" "spread" {
  name     = "${var.ami_prefix}_${var.azp_pool_name}_placement_group"
  strategy = "spread"
}

resource "aws_launch_template" "build_pool" {
  name_prefix   = "${var.ami_prefix}_${var.azp_pool_name}"
  image_id      = data.aws_ami.azp_ci_image.id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.disk_size_gb
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.asg_iam_instance_profile.arn
  }

  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = "envoy-shared"
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }
  user_data              = base64encode(data.template_file.init.rendered)
  vpc_security_group_ids = ["sg-0e26fd7adddb1b9fa"]
}

resource "aws_autoscaling_group" "build_pool" {
  name            = local.asg_name
  placement_group = aws_placement_group.spread.id

  min_size         = var.idle_instances_count
  desired_capacity = var.idle_instances_count
  max_size         = 50

  health_check_grace_period = 300
  health_check_type         = "EC2"

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.build_pool.id
        version            = "$Latest"
      }

      override {
        instance_type = var.instance_type
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_instances_count
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 5
    }
  }

  tags = [
    {
      key                 = "PoolName"
      value               = var.azp_pool_name
      propagate_at_launch = true
    }
  ]

  # The ones with r6g.* available.
  availability_zones = [
    "us-east-1a",
    "us-east-1c",
    "us-east-1d",
    "us-east-1f",
  ]
}
