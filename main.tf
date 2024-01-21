provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project"
  }
}

resource "aws_subnet" "subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)

  map_public_ip_on_launch = true

  tags = {
    Name = "project-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  ami                = "ami-06aa3f7caf3a30282"  
  instance_type      = "t2.micro"
  key_name           = "project1"
  subnet_id          = aws_subnet.subnet[0].id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = "project-instance"
  }

}

resource "aws_security_group" "rds_sg" { 
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]    
}
ingress {
    from_port   = 5432  
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

}

resource "aws_db_subnet_group" "db_subnet_group-1" {
  name       = "project-db-subnet-group"
  subnet_ids = aws_subnet.subnet[*].id
}

resource "aws_db_instance" "db_instance" {
  identifier              = "database-10"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "15.4"
  instance_class          = "db.t3.micro"
  db_name                 = "database10"
  username                = "postgres"
  password                = "anupam123" 
  parameter_group_name    = "default.postgres15"
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group-1.name
  skip_final_snapshot     = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "example-db"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}

output "rds_port" {
  value = aws_db_instance.db_instance.port
}

output "rds_db_name" {
  value = aws_db_instance.db_instance.db_name
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}
output "instance" {
  value = aws_instance.instance.public_ip
}


output "rds_username" {
  value = aws_db_instance.db_instance.username
}
