resource "aws_iam_role" "k8-ec2-role" {
  name               = "k8-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "k8_iam_role_policy" {
  name   = "k8_iam_role_policy"
  role   = aws_iam_role.k8-ec2-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "${aws_secretsmanager_secret.k8_ct_auth_key.arn}"
    },
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:PutSecretValue","secretsmanager:UpdateSecret"],
      "Resource": "${aws_secretsmanager_secret.k8_ct_auth_key.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "k8-ec2-role" {
  name = "k8-ec2-role"
  role = aws_iam_role.k8-ec2-role.name
}

resource "aws_iam_role_policy_attachment" "ssm-policy" {
  role       = aws_iam_role.k8-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


#Creating a AWS secret 

resource "aws_secretsmanager_secret" "k8_ct_auth_key" {
  name                    = "k8_ct_auth_key"
  description             = "Kubernetes join command for worker nodes"
  recovery_window_in_days = 0
  # Depend on the null_resource to ensure recreation when the instance is recreated
  # depends_on = [null_resource.instance_recreate_trigger]

  # Use a lifecycle block to recreate the secret before it's destroyed
  # lifecycle {
  #   create_before_destroy = true
  # }
}



data "template_file" "user_data_ct" {
  template = file("controlplane.tpl")
  vars = {
    k8_ct_auth_key = aws_secretsmanager_secret.k8_ct_auth_key.name
    lb_dns         = aws_elb.k8_api_lb.dns_name
  }
}


resource "aws_instance" "ct1" {
  #   for_each      = toset(local.instances)
  ami = data.aws_ami.ubuntu.image_id
  # key_name                    = "2023-key"
  instance_type               = var.control_panel_instance_type
  user_data                   = data.template_file.user_data_ct.rendered
  iam_instance_profile        = aws_iam_instance_profile.k8-ec2-role.name
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  user_data_replace_on_change = true
  tags = {
    "Name" = "k8-ct1",
  }
  depends_on = [aws_secretsmanager_secret.k8_ct_auth_key, aws_elb.k8_api_lb]
}


data "template_file" "user_data_worker" {
  template = file("workernodes.tpl")
  vars = {
    k8_ct_auth_key = aws_secretsmanager_secret.k8_ct_auth_key.name
  }
}


resource "aws_launch_configuration" "worker_lc" {
  name_prefix                 = "worker-lc"
  image_id                    = data.aws_ami.ubuntu.image_id
  instance_type               = var.worker_instance_type
  user_data                   = data.template_file.user_data_worker.rendered
  iam_instance_profile        = aws_iam_instance_profile.k8-ec2-role.name
  security_groups             = [aws_security_group.calico.id, aws_security_group.worker_sg.id]
  associate_public_ip_address = false
  lifecycle {
    create_before_destroy = true
  }
  # If using spot instances
  spot_price = var.capacity_type == "SPOT" ? "0.0031" : null
  # Uncomment this if you have a specific key name you want to use
  # key_name = "2023-key"
}

resource "aws_autoscaling_group" "worker_asg" {
  name                 = "k8-worker-asg"
  desired_capacity     = var.worker_nodes_count
  max_size             = var.worker_nodes_count + 0 // You can set this to what you consider a sensible maximum
  min_size             = var.worker_nodes_count
  vpc_zone_identifier  = module.vpc.private_subnets
  launch_configuration = aws_launch_configuration.worker_lc.id

  tag {
    key                 = "Name"
    value               = "worker-node"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    # preferences {
    #   instance_warmup        = 300
    #   min_healthy_percentage = 50
    # }
  }

  depends_on = [aws_instance.ct1]
  lifecycle {
    create_before_destroy = true
  }
}
