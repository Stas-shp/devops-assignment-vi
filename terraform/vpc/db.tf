# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "docdb_subnet_group" {
  name       = "my-docdb-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "MyDocDBSubnetGroup"
  }
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "my_docdb_cluster" {
  cluster_identifier     = "my-docdb-cluster"
  engine                 = "docdb"
  master_username        = "viadmin"            # Change as required
  master_password        = var.model_mongo_pass # Change as required, and consider using a secrets manager
  db_subnet_group_name   = aws_docdb_subnet_group.docdb_subnet_group.name
  vpc_security_group_ids = [aws_security_group.docdb_sg.id]
  skip_final_snapshot    = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.my_docdb_cluster_parameter_group.name

  tags = {
    Name = "MyDocDBCluster"
  }
}

# DocumentDB Cluster Instance
resource "aws_docdb_cluster_instance" "my_docdb_instance" {
  count              = 1
  identifier         = "my-docdb-instance"
  cluster_identifier = aws_docdb_cluster.my_docdb_cluster.id
  instance_class     = "db.t3.medium" # Change as necessary based on your performance and cost requirements

  tags = {
    Name = "MyDocDBInstance"
  }
}

# Security Group for DocumentDB - allowing access from instances within the VPC
resource "aws_security_group" "docdb_sg" {
  name        = "docdb-sg"
  description = "Security group for DocumentDB cluster"
  vpc_id      = aws_vpc.my_vpc.id

  # Example rule - restrict to specific CIDR blocks or security groups
  # Here, allowing access from the VPC CIDR range
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docdb-security-group"
  }
}

# Associate the Security Group with the DocumentDB Cluster
resource "aws_docdb_cluster_parameter_group" "my_docdb_cluster_parameter_group" {
  name   = "my-docdb-cluster-parameter-group"
  family = "docdb5.0" # Change as per the latest or required DocumentDB engine version

  parameter {
    name  = "tls"
    value = "disabled"
  }

}
