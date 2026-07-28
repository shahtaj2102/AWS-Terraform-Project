#############################################
# Compute layer: EC2 (via Auto Scaling Group)
# behind an Application Load Balancer.
#
# Traffic flow:
#   Internet -> ALB (public subnets) -> Target Group
#            -> EC2 instances (private subnets, via ASG)
#
# Instances are never directly reachable from the
# internet - only the ALB's security group is allowed
# to reach them, and outbound updates go through the
# NAT Gateway already provisioned in main.tf.
#############################################

# Latest Amazon Linux 2023 AMI, looked up dynamically
# so this doesn't go stale or need manual updates.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#############################################
# Security Groups
#############################################

# ALB security group: accepts HTTP from the internet.
resource "aws_security_group" "alb_sg" {
  name        = "${var.vpc_name}-alb-sg"
  description = "Allow inbound HTTP from the internet to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.vpc_name}-alb-sg"
    Terraform = "true"
  }
}

# App/instance security group: only accepts traffic
# from the ALB security group, not directly from the
# internet - this is the actual point of putting the
# instances in private subnets behind a load balancer.
resource "aws_security_group" "app_sg" {
  name        = "${var.vpc_name}-app-sg"
  description = "Allow inbound HTTP only from the ALB security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.vpc_name}-app-sg"
    Terraform = "true"
  }
}

#############################################
# Launch Template + Auto Scaling Group
#############################################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.vpc_name}-app-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Minimal user data: installs and starts a basic web
  # server so the ALB health check and a browser request
  # both have something real to hit - just enough to prove
  # the architecture works end-to-end, not a real app.
  user_data = base64encode(<<-EOF
#!/bin/bash
dnf install -y httpd
echo "Hello from $(hostname -f) - AWS-Terraform-Project compute layer" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${var.vpc_name}-app-instance"
      Terraform = "true"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.vpc_name}-app-asg"
  desired_capacity    = var.asg_desired_capacity
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  vpc_zone_identifier = [for s in aws_subnet.private_subnets : s.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-app-asg"
    propagate_at_launch = true
  }
}

#############################################
# Application Load Balancer
#############################################

resource "aws_lb" "app_alb" {
  # ALB names can't contain underscores, unlike most other
  # resource names in this project - sanitize vpc_name here
  # so this stays valid even though var.vpc_name has one.
  name               = "${replace(var.vpc_name, "_", "-")}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public_subnets : s.id]

  tags = {
    Name      = "${var.vpc_name}-alb"
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${replace(var.vpc_name, "_", "-")}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name      = "${var.vpc_name}-app-tg"
    Terraform = "true"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
