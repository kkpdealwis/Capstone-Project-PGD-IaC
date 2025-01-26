
resource "aws_vpc" "EDUREKA-PDP-VPC" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name                                 = "EDUREKA-PDP-VPC"
    User                                 = "Terraform-User"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"     = "owned"
  }
}

resource "aws_subnet" "EDUREKA-PDP-SUBNET-PUBLIC" {
  vpc_id                  = aws_vpc.EDUREKA-PDP-VPC.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                                 = "EDUREKA-PDP-SUBNET-PUBLIC"
    User                                 = "Terraform"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"     = "owned"
  }
}

/*
resource "aws_subnet" "EDUREKA-PDP-SUBNET-PRIVATE" {
  vpc_id            = aws_vpc.EDUREKA-PDP-VPC.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name     = "EDUREKA-PDP-SUBNET-PRIVATE"
    user     = "Terraform-User"
    Duration = "1day"
  }
}
*/

resource "aws_internet_gateway" "EDUREKA-PDP-IGW" {
  vpc_id = aws_vpc.EDUREKA-PDP-VPC.id
  tags = {
    Name     = "EDUREKA-PDP-IGW"
    User     = "Terraform-User"
    Duration = "1day"
  }
}

/*
resource "aws_eip" "EDUREKA-PDP-NAT-PUB-IP" {
  network_border_group = "us-east-1"
  public_ipv4_pool     = "amazon"
  vpc                  = true
  tags = {
    Name     = "EDUREKA-PDP-NAT-PUB-IP"
    User     = "Terraform-User"
    Duration = "1day"
  }
  tags_all = {
    Name = "EDUREKA-PDP-NAT-PUB-IP"
  }
}
resource "aws_nat_gateway" "EDUREKA-PDP-NAT-GW" {
  allocation_id = aws_eip.EDUREKA-PDP-NAT-PUB-IP.id
  subnet_id     = aws_subnet.EDUREKA-PDP-SUBNET-PUBLIC.id
  tags = {
    Name     = "EDUREKA-PDP-NAT-GW"
    User     = "Terraform-User"
    Duration = "1day"
  }
}
*/

resource "aws_route_table" "EDUREKA-PDP-ROUTE-TABLE-PUBLIC" {
  vpc_id = aws_vpc.EDUREKA-PDP-VPC.id
  tags = {
    Name                                 = "EDUREKA-PDP-ROUTE-TABLE-PUBLIC"
    User                                 = "Terraform-User"
    Duration                             = "1day"
    "kubernetes.io/cluster/kubernetes"     = "owned"
  }
}

/*
resource "aws_route_table" "EDUREKA-PDP-ROUTE-TABLE-PRIVATE" {
  vpc_id = aws_vpc.EDUREKA-PDP-VPC.id
  tags = {
    Name     = "EDUREKA-PDP-ROUTE-TABLE-PRIVATE"
    User     = "Terraform-User"
    Duration = "1day"
  }
}
*/

resource "aws_route" "EDUREKA-PDP-ROUTE-PUBLIC" {
  route_table_id         = aws_route_table.EDUREKA-PDP-ROUTE-TABLE-PUBLIC.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.EDUREKA-PDP-IGW.id
}

/*
resource "aws_route" "EDUREKA-PDP-ROUTE-PRIVATE" {
  route_table_id         = aws_route_table.EDUREKA-PDP-ROUTE-TABLE-PRIVATE.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.EDUREKA-PDP-NAT-GW.id
}
*/

resource "aws_route_table_association" "EDUREKA-PDP-ROUTE-TABLE-PUBLIC-ASSOCIATION" {
  subnet_id      = aws_subnet.EDUREKA-PDP-SUBNET-PUBLIC.id
  route_table_id = aws_route_table.EDUREKA-PDP-ROUTE-TABLE-PUBLIC.id
}

/*
resource "aws_route_table_association" "EDUREKA-PDP-ROUTE-TABLE-PRIVATE-ASSOCIATION" {
  subnet_id      = aws_subnet.EDUREKA-PDP-SUBNET-PRIVATE.id
  route_table_id = aws_route_table.EDUREKA-PDP-ROUTE-TABLE-PRIVATE.id
}
*/

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
