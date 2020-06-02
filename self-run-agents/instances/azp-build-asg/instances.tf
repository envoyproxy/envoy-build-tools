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

  # You can still terminate these instances, but it requires an
  # Extra manual step which is ideal to make sure no ones builds
  # get wrecked.
  disable_api_termination              = true
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

  min_size         = var.guaranteed_instances_count
  desired_capacity = var.guaranteed_instances_count
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
      on_demand_base_capacity = var.guaranteed_instances_count
      # TODO(cynthia): Rework to allow spots and bring this down to 0 again.
      on_demand_percentage_above_base_capacity = 100
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  # Instances will set manually.
  protect_from_scale_in = false

  tags = [
    {
      key                 = "PoolName"
      value               = var.azp_pool_name
      propagate_at_launch = true
    }
  ]

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }

  # use1-az6, use1-az2, use1-az4
  # The ones with a1.4xl's.
  vpc_zone_identifier = ["subnet-29a65576", "subnet-33e41912", "subnet-b88b0df5"]
}

# Can't use the recommend initial_lifecycle_hook due to:
# https://github.com/terraform-providers/terraform-provider-aws/issues/9841
#
# This will probably never be a problem since the only window would be between
# ASG Creation + Lifecycle Hook Creation which should be immediate, and doubtful
# we'll terminate any instances then.
#
# If we do we can do a one off delete.
resource "aws_autoscaling_lifecycle_hook" "lifecycle_hook" {
  name                    = "${var.ami_prefix}_${var.azp_pool_name}_azure_dereg_hook"
  default_result          = "CONTINUE"
  heartbeat_timeout       = 2000
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = var.sns_lifecycle_arn
  role_arn                = var.sns_lifecyle_role_arn

  autoscaling_group_name = aws_autoscaling_group.build_pool.name
}

resource "aws_autoscaling_policy" "nodes-on-demand" {
  autoscaling_group_name = aws_autoscaling_group.build_pool.name
  name                   = "${var.ami_prefix}_${var.azp_pool_name}_tt"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # Someone shold probably apply Queue'ing theory to this to make it
    # actually a reasonable number, for now 60 seems like it'll work
    # since builds take 100% CPU, so this means more than half of our
    # workers are busy.
    target_value = 60.0
  }
}
