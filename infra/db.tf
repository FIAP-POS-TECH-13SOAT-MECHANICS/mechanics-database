resource "aws_db_instance" "database" {
  identifier              = "${local.prefix}-db"
  allocated_storage       = 20
  engine                  = "sqlserver-ex"
  engine_version          = "15.00"
  instance_class          = "db.t3.small"
  username                = random_string.database_user.result
  password                = random_string.database_password.result
  storage_encrypted       = true
  timezone                = "E. South America Standard Time"
  storage_type            = "gp3"
  publicly_accessible     = local.public
  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 0

  db_subnet_group_name   = aws_db_subnet_group.mssql.name
  vpc_security_group_ids = [aws_security_group.mssql.id]
}

resource "aws_db_subnet_group" "mssql" {
  name        = "${local.prefix}-db"
  description = "Subnet group for RDS"

  subnet_ids = local.public ? aws_subnet.public[*].id : aws_subnet.private[*].id
}

resource "aws_security_group" "mssql" {
  name        = "${local.prefix}-mssql-sg"
  description = "Security group for SQL Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = local.public ? ["0.0.0.0/0"] : [var.vpc_cidr]
    description = local.public ? "SQL Server - Public Access" : "SQL Server - Internal VPC Only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = local.public ? "mssql-public-${var.environment}" : "mssql-private-${var.environment}"
  }
}
