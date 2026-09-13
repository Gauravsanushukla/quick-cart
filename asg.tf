# AMI Data Source (Amazon Linux 2023)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Launch Template
resource "aws_launch_template" "lt" {
  name_prefix   = "quickcart-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = "keypair_august"  # Replace with your actual key pair name

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = filebase64("${path.module}/userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "quickcart-asg-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name_prefix         = "quickcart-asg-"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.tg.arn]

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Scaling Policy: Target Tracking CPU 50%
resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "quickcart-cpu-50-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}