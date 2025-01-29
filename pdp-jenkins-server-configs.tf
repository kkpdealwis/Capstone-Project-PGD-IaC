//create IAM role with attaching AmazonSSMManagedInstanceCore AWS managed policy
data "aws_iam_policy" "ec2-ssm-policy" {
  name = "AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role" "ec2-ssm-role" {
  name = "ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "EC2SSMRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name       = "Dev-SSM-Role"
    Department = "DevOps"
    Email      = "kkpdealwis@gmail.com"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-role-policy-attachment" {
  role       = aws_iam_role.ec2-ssm-role.name
  policy_arn = data.aws_iam_policy.ec2-ssm-policy.arn
}

resource "aws_iam_instance_profile" "ec2-ssm-instance-profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2-ssm-role.name
}

resource "aws_security_group" "JEKINS-SERVER-SG" {
  name        = "JENKINS-SERVER-SG"
  description = "Jenkins Server AWS Security Group"
  vpc_id      = aws_vpc.EDUREKA-PDP-VPC.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name     = "JENKINS-SERVER-SG"
    User     = "vscode"
    Duration = "1day"
  }
}

resource "aws_key_pair" "jenkins-server-key" {
  key_name = "jenkins-server-key"
  //public_key = "${var.JENKINS_SERVER_PUB_KEY}"
  public_key = file("jenkins-server-key.pub")
}
resource "aws_instance" "JENKINS-SERVER-INSTANCE" {
  ami                         = "ami-0e2c8caa4b6378d8c"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.jenkins-server-key.key_name
  vpc_security_group_ids      = [aws_security_group.JEKINS-SERVER-SG.id]
  subnet_id                   = aws_subnet.EDUREKA-PDP-SUBNET-PUBLIC.id
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm-instance-profile.name
  associate_public_ip_address = true
  user_data                   = file("configure-jenkins-server.sh")
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
  volume_tags = {
    Name     = "JENKINS-SERVER-INSTANCE"
    User     = "Terraform-User"
    Duration = "1day"
  }
  tags = {
    Name     = "JENKINS-SERVER-INSTANCE"
    User     = "Terraform-User"
    Duration = "1day"
  }
}