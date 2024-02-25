resource "aws_security_group" "control_plane_sg" {
  name        = "control-plane-sg"
  description = "Security group for Kubernetes control-plane nodes"
  vpc_id      = module.vpc.vpc_id
}


# Inbound rules for control plane
resource "aws_security_group_rule" "control_plane_ingress_api_server_self" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}

# Inbound rules for control plane
resource "aws_security_group_rule" "control_plane_ingress_api_server_all" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "control_plane_ingress_api_server_self_10257" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 10257
  to_port           = 10257
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}
resource "aws_security_group_rule" "control_plane_ingress_api_server_self_10259" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 10259
  to_port           = 10259
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}
resource "aws_security_group_rule" "control_plane_ingress_api_server_self_10250" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}

resource "aws_security_group_rule" "control_plane_ingress_api_server_self_2379_2380" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}

resource "aws_security_group_rule" "control_plane_ingress_api_server_worker_10250" {
  security_group_id        = aws_security_group.control_plane_sg.id
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "control_plane_egress" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


# Worker Security Group
resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = module.vpc.vpc_id
}


resource "aws_security_group_rule" "workers_ingress" {
  security_group_id = aws_security_group.worker_sg.id
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group
}

resource "aws_security_group_rule" "worker_ingress_10250" {
  security_group_id = aws_security_group.worker_sg.id
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true # Allows traffic from resources within the same security group

}


resource "aws_security_group_rule" "worker_ingress_control_plane" {
  security_group_id        = aws_security_group.worker_sg.id
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
}

resource "aws_security_group_rule" "worker_egress" {
  security_group_id = aws_security_group.worker_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}




# Security group for communication between calico pods
# Applied to all nodes
resource "aws_security_group" "calico" {
  name   = "calico"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "calico_bgp" {
  description                  = "bgp"
  from_port                    = 179
  to_port                      = 179
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}

resource "aws_vpc_security_group_ingress_rule" "calico_ip_in_ip" {
  description                  = "ip-in-ip"
  ip_protocol                  = "4"
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}

resource "aws_vpc_security_group_ingress_rule" "calico_vxlan" {
  description                  = "vxlan"
  from_port                    = 4789
  to_port                      = 4789
  ip_protocol                  = "udp"
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}

resource "aws_vpc_security_group_ingress_rule" "calico_typha" {
  description                  = "typha"
  from_port                    = 5473
  to_port                      = 5473
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}

resource "aws_vpc_security_group_ingress_rule" "calico_wireguard" {
  description                  = "wireguard"
  from_port                    = 51820
  to_port                      = 51821
  ip_protocol                  = "udp"
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}


resource "aws_vpc_security_group_ingress_rule" "calico_apiserver" {
  description                  = "api-server gossip"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  security_group_id            = aws_security_group.calico.id
  referenced_security_group_id = aws_security_group.calico.id
}

