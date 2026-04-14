data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_lb" "web" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.web_security_group_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -eux

              dnf update -y
              dnf install -y nginx

              cat > /usr/share/nginx/html/index.html <<HTML
              <!DOCTYPE html>
              <html>
              <head>
                <title>Welcome</title>
              </head>
              <body>
                <h1>NGINX welcome page</h1>
                <p>Host: $(hostname)</p>
                <p>Project: ${var.project_name}</p>
                <p>Environment: ${var.environment}</p>
              </body>
              </html>
              HTML

              systemctl enable nginx
              systemctl restart nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-web"
      Role = "web"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lt"
  })
}

resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-${var.environment}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 120
  vpc_zone_identifier       = var.web_subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "web"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}