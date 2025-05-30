terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "projekat2-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "projekat2-igw" }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "projekat2-public-subnet-a" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "projekat2-public-subnet-b" }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "projekat2-private-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "projekat2-public-rt" }
}

resource "aws_route_table_association" "public_rt_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ec2-sg"
  
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
  
  tags = { Name = "projekat2-ec2-sg" }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = "alb-sg"
  
  
  ingress {
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
  
  tags = { Name = "projekat2-alb-sg" }
}

resource "aws_ebs_volume" "db_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  type              = "gp2"
  tags              = { Name = "projekat2-db-volume" }
}

resource "aws_instance" "app_instance" {
  ami                    = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  key_name               = "vockey"
  
  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x
    
    echo "*** Početak User Data skripte ***"
    
    
    sudo yum update -y
    sudo yum install -y docker git jq
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    
    
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
   
    sudo mkfs.ext4 /dev/xvdf
    sudo mkdir -p /mnt/db_data
    sudo mount /dev/xvdf /mnt/db_data
    sudo chown ec2-user:ec2-user /mnt/db_data
    sudo mkdir -p /mnt/db_data/postgresql
    
    
    git clone https://github.com/amilaresidovic/projekat2.git /home/ec2-user/projekat2
    cd /home/ec2-user/projekat2
    
    
    ALB_DNS=$(aws elbv2 describe-load-balancers --names projekat2-alb --query 'LoadBalancers[0].DNSName' --output text)
    
    cat > /home/ec2-user/projekat2/vite.config.js <<VITECONFIG
    import { defineConfig } from "vite";
    import react from "@vitejs/plugin-react";
    
    export default defineConfig({
      base: "/",
      plugins: [react()],
      server: {
        port: 8080,
        strictPort: true,
        host: "0.0.0.0",
        allowedHosts: [
          "${ALB_DNS}",
          "localhost",
          "127.0.0.1",
        ],
      },
    });
    VITECONFIG
    
    
    sudo ln -s /mnt/db_data/postgresql /home/ec2-user/projekat2/db_data
    
    
    sudo docker-compose build
    sudo docker-compose up -d
    
    
    echo "Čekam da aplikacija bude spremna..."
    for i in {1..30}; do
      if curl -s http://localhost:8080 >/dev/null; then
        echo "Aplikacija je pokrenuta!"
        break
      fi
      sleep 10
      echo "Pokušaj $i/30: Aplikacija još nije spremna..."
    done
    
    echo "*** Završetak User Data skripte ***"
    
    
    sudo docker ps -a >> /var/log/user-data.log
    curl -I http://localhost:8080 >> /var/log/user-data.log
    EOF

  tags = { Name = "projekat2-app-instance" }

  depends_on = [
    aws_lb.app_alb,
    aws_ebs_volume.db_volume
  ]
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.db_volume.id
  instance_id = aws_instance.app_instance.id
}

resource "aws_lb" "app_alb" {
  name               = "projekat2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  
  enable_deletion_protection = false
  
  tags = { Name = "projekat2-alb" }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "projekat2-frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-399"
  }
  
  tags = { Name = "projekat2-frontend-tg" }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "projekat2-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  
  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-399"
  }
  
  tags = { Name = "projekat2-backend-tg" }
}

resource "aws_lb_target_group_attachment" "frontend_tg_attachment" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.app_instance.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "backend_tg_attachment" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.app_instance.id
  port             = 5000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "instance_public_ip" {
  value = aws_instance.app_instance.public_ip
}