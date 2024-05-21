Here is Terraform configuration for a highly available web application deployment with the requested components:

```hcl
# VPC module to deploy VPC with public and private subnets, route tables, IGW etc 
module "vpc" {
  source = "org/vpc/aws"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
   
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# S3 module to create S3 bucket for static assets
module "s3" {
  source = "org/s3/aws"
  
  bucket = "my-app-assets"
  acl    = "private"

  tags = {
    Terraform = "true"  
  }
}

# Application Load Balancer to distribute traffic across EC2 instances
resource "aws_lb" "web" {
  name               = "web-lb"  
  internal           = false  
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]  
  subnets            = module.vpc.public_subnets
}

# Auto Scaling group to scale EC2 instances based on demand  
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"  
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
} 

# Launch template to configure EC2 instances 
resource "aws_launch_template" "web" {
  name                   = "web-lt"
  image_id               = data.aws_ami.ubuntu.id 
  instance_type          = "t3.small"
  key_name               = "my-key"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups = [module.vpc.web_security_group_id]    
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y 
              sudo systemctl start apache2
              sudo bash -c 'echo Web Server Up > /var/www/html/index.html'            
              EOF
  )
  
  tags = {
    Name = "web-lt"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target group to route requests from ALB to ASG
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id 
  
  health_check {
    path = "/"
  }
}

# Listener rule to forward requests from ALB to target group
resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Listener for ALB to listen on port 80
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"  
}

# Attach ASG to ALB target group
resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  alb_target_group_arn   = aws_lb_target_group.web.arn
}

# RDS Postgres database instance
resource "aws_db_instance" "postgres" {
  engine              = "postgres"
  engine_version      = "12.3"  
  instance_class      = "db.t3.micro"
  
  name                = "mydb"
  username            = "admin"
  password            = random_password.postgres.result
  
  vpc_security_group_ids = [module.vpc.database_security_group_id]
  db_subnet_group_name = aws_db_subnet_group.postgres.name
  
  backup_retention_period = 7  
  multi_az               = true
  
  skip_final_snapshot    = true
} 

# DB subnet group to deploy RDS in VPC  
resource "aws_db_subnet_group" "postgres" {
  name = "postgres-subnet"
  subnet_ids = module.vpc.private_subnets
}

# IAM role and instance profile for EC2 access to S3
resource "aws_iam_role" "web" {
  name = "web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "web" {
  name = "web-profile"
  role = aws_iam_role.web.name
}

resource "aws_iam_role_policy" "s3_access" {
  name = "S3AccessPolicy"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = module.s3.arn
      },
    ]
  })
}

# Password for RDS 
resource "random_password" "postgres" {
  length = 16
  special = false  
}

# Get latest Ubuntu 20.04 AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
```

This sets up a highly available architecture with auto scaling, load balancing, RDS database and S3 for static assets. Security best practices are followed by using IAM roles and security groups.