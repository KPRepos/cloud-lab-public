

resource "aws_elb" "k8_api_lb" {
  # count           = var.enable_k8_api_public ? 1 : 0
  name            = "k8-api-lb"
  subnets         = [module.vpc.public_subnets[0]] // Use your public subnet ID
  security_groups = [aws_security_group.k8_api_lb_sg.id]

  listener {
    instance_port     = 6443 // Kubernetes API server port
    instance_protocol = "TCP"
    lb_port           = 6443
    lb_protocol       = "TCP"
  }

  health_check {
    target              = "TCP:6443"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # instances                   = [aws_instance.ct1.id] // Use your control plane instance ID
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "k8-api-lb"
  }
}


resource "aws_elb_attachment" "ct1_attach" {
  elb      = aws_elb.k8_api_lb.id
  instance = aws_instance.ct1.id
}

resource "aws_security_group" "k8_api_lb_sg" {
  # count       = var.enable_k8_api_public ? 1 : 0
  name        = "k8-api-lb-sg"
  description = "Security group for Kubernetes API load balancer"
  vpc_id      = module.vpc.vpc_id // Use your VPC ID
  tags = {
    Name = "k8-api-lb-sg"
  }
}


# Outbound rules for control plane
resource "aws_security_group_rule" "lb_egress" {
  security_group_id = aws_security_group.k8_api_lb_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


# Inbound rules for control plane
resource "aws_security_group_rule" "lb_local_vpc_ip" {
  security_group_id = aws_security_group.k8_api_lb_sg.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

# Inbound rules for control plane
resource "aws_security_group_rule" "lb_local_vpc_ip_443" {
  security_group_id = aws_security_group.k8_api_lb_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}


# Inbound rules for control plane
resource "aws_security_group_rule" "lb_ingress_user_public_ip" {
  count             = var.add_user_local_ip_to_lb ? 1 : 0
  security_group_id = aws_security_group.k8_api_lb_sg.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["${local.public_ip}/32"]
}


# Inbound rules for control plane
resource "aws_security_group_rule" "lb_ingress_allowed_ip" {
  count             = length(var.allowed_cidrs_k8_public_dns) > 0 ? 1 : 0
  security_group_id = aws_security_group.k8_api_lb_sg.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs_k8_public_dns
}


resource "aws_security_group_rule" "allow_lb_to_ct1_6443" {
  # count = var.enable_k8_api_public ? 1 : 0
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.control_plane_sg.id
  source_security_group_id = aws_security_group.k8_api_lb_sg.id
}

resource "aws_security_group_rule" "allow_IGW_to_LB_6443" {
  # count = var.enable_k8_api_public ? 1 : 0
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.k8_api_lb_sg.id
  cidr_blocks       = formatlist("%s/32", module.vpc.nat_public_ips)
}
