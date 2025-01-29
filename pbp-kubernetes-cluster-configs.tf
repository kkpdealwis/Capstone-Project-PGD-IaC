//create IAM role with attaching AmazonSSMManagedInstanceCore AWS managed policy
resource "aws_iam_policy" "k8s-master-policy" {
  name        = "K8SMasterPolicy"
  description = "K8S Master Node IAM Policy"
  policy      = file("k8s-master-iam-policy.json")
}

resource "aws_iam_policy" "k8s-worker-policy" {
  name        = "K8SWorkerPolicy"
  description = "K8S Worker Node IAM Policy"
  policy      = file("k8s-worker-iam-policy.json")
}

locals {
  k8s_master_policy_arns = {
    AmazonSSMManagedInstanceCore = data.aws_iam_policy.ec2-ssm-policy.arn
    K8SMasterPolicy              = aws_iam_policy.k8s-master-policy.arn
  }
  k8s_worker_policy_arns = {
    AmazonSSMManagedInstanceCore = data.aws_iam_policy.ec2-ssm-policy.arn
    K8SWorkerPolicy              = aws_iam_policy.k8s-worker-policy.arn
  }

}

resource "aws_iam_role" "ec2-ssm-role-k8s-master" {
  name = "ec2-ssm-role-k8s-master"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "EC2SSMRoleK8SMaster"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name       = "Dev-SSM-Role-K8S-Master"
    Department = "DevOps"
    Email      = "kkpdealwis@gmail.com"
  }
}

resource "aws_iam_role" "ec2-ssm-role-k8s-worker" {
  name = "ec2-ssm-role-k8s-worker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "EC2SSMRoleK8SWorker"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name       = "Dev-SSM-Role-K8S-Worker"
    Department = "DevOps"
    Email      = "kkpdealwis@gmail.com"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-k8s-master-policy-attachment" {
  for_each   = local.k8s_master_policy_arns
  role       = aws_iam_role.ec2-ssm-role-k8s-master.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "ec2-k8s-worker-policy-attachement" {
  for_each   = local.k8s_worker_policy_arns
  role       = aws_iam_role.ec2-ssm-role-k8s-worker.name
  policy_arn = each.value
}
resource "aws_iam_instance_profile" "ec2-ssm-instance-profile-k8s-master" {
  name = "ec2-ssm-instance-profile-k8s-master"
  role = aws_iam_role.ec2-ssm-role-k8s-master.name
}

resource "aws_iam_instance_profile" "ec2-ssm-instance-profile-k8s-worker" {
  name = "ec2-ssm-instance-profile-k8s-worker"
  role = aws_iam_role.ec2-ssm-role-k8s-worker.name
}
//create t2.medium kubernetes master node
resource "aws_security_group" "k8s-master-node-sg" {
  vpc_id      = aws_vpc.EDUREKA-PDP-VPC.id
  name        = "k8s-master-node-sg"
  description = "k8s master node security group"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                                 = "k8s-master-node-sg"
    "kubernetes.io/cluster/kubernetes"   = "owned"
  }
}

resource "aws_key_pair" "k8s-master-node-key" {
  key_name   = "k8s-master-node-key"
  public_key = file("k8s-master-node-key.pub")
}

resource "aws_key_pair" "k8s-worker-node-key" {
  key_name   = "k8s-worker-node-key"
  public_key = file("k8s-worker-node-key.pub")
}

resource "aws_instance" "K8S-MASTER-NODE-INSTANCE" {
  ami                         = "ami-0e2c8caa4b6378d8c"
  instance_type               = "t2.medium"
  key_name                    = "k8s-worker-node-key"
  vpc_security_group_ids      = [aws_security_group.k8s-master-node-sg.id]
  subnet_id                   = aws_subnet.EDUREKA-PDP-SUBNET-PUBLIC.id
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm-instance-profile-k8s-master.name
  associate_public_ip_address = true
  user_data                   = file("configure-worker-k8s-server.sh")
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
  volume_tags = {
    Name     = "K8S-MASTER-NODE-INSTANCE"
    User     = "Terraform-User"
    Duration = "1day"
  }
  tags = {
    Name                                 = "K8S-MASTER-NODE-INSTANCE"
    User                                 = "Terraform-User"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"   = "owned"
  }

}

# create t2.medium kubernetes worker node
resource "aws_security_group" "k8s-worker-node-sg" {
  vpc_id      = aws_vpc.EDUREKA-PDP-VPC.id
  name        = "k8s-worker-node-sg"
  description = "k8s worker node security group"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                                 = "k8s-worker-node-sg"
    "kubernetes.io/cluster/kubernetes"     = "owned"
  }
}

resource "aws_instance" "K8S-WORKER-NODE-INSTANCE" {
  ami                         = "ami-0e2c8caa4b6378d8c"
  instance_type               = "t2.medium"
  key_name                    = "k8s-worker-node-key"
  vpc_security_group_ids      = [aws_security_group.k8s-worker-node-sg.id]
  subnet_id                   = aws_subnet.EDUREKA-PDP-SUBNET-PUBLIC.id
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm-instance-profile-k8s-worker.name
  associate_public_ip_address = true
  user_data                   = file("configure-worker-k8s-server.sh")
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
  volume_tags = {
    Name                                 = "K8S-WORKER-NODE-INSTANCE"
    User                                 = "Terraform-User"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"   = "owned"
  }
  tags = {
    Name                                 = "K8S-WORKER-NODE-INSTANCE"
    User                                 = "Terraform-User"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"   = "owned"
  }

}