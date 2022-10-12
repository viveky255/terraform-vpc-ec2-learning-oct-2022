
# Creating VPC,name, CIDR and Tags

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = "true"
    enable_dns_support =  "true"

    tags = {
      "Name" = "${var.env_prefix}-vpc"
    }

}

# Creating Public Subnets in VPC

resource "aws_subnet" "myapp-public-subnet" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.public_subnet_cidr_block
    map_public_ip_on_launch = "true"
    availability_zone = var.availa_zone_public

    tags = {
      "Name" = "${var.env_prefix}-public-subnet"
    }
 
}

# Creating Private Subnets in VPC

resource "aws_subnet" "myapp-private-subnet" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.private_subnet_cidr_block
    map_public_ip_on_launch = "false"
    availability_zone = var.availa_zone_private

    tags = {
      "Name" = "${var.env_prefix}-private-subnet"
    }
 
}

# Creating Internet Gateway in AWS VPC

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
      "Name" = "${var.env_prefix}-igw"
    }
  
}

# Creating Route Tables for Internet gateway

resource "aws_default_route_table" "myapp-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

     tags = {
      "Name" = "${var.env_prefix}-rtb-public"
    }
  
}

# Creating Route Associations public subnets

resource "aws_route_table_association" "myapp-rtb-public-subnet" {
    subnet_id = aws_subnet.myapp-public-subnet.id
    route_table_id = aws_default_route_table.myapp-rtb.id
  
}

# Creating security group

resource "aws_security_group" "myapp-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress  {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    

     tags = {
      "Name" = "${var.env_prefix}-sg"
    }
  
}

# Creating Nat Gateway
resource "aws_eip" "nat" {
    vpc = true
  
}
resource "aws_nat_gateway" "myapp-ntw" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.myapp-public-subnet.id
    depends_on    = [aws_internet_gateway.myapp-igw]

    tags = {
    Name = "${var.env_prefix}-ntw"
  }

}

# Add routes for private subnet
resource "aws_route_table" "myapp-rtb-private" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.myapp-ntw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb-private"
  }
}

# Creating route associations for private Subnets

resource "aws_route_table_association" "myapp-rtb-private-subnet" {
    subnet_id = aws_subnet.myapp-private-subnet.id
    route_table_id = aws_route_table.myapp-rtb-private.id
  
}

data "aws_ami" "amazon" {
    owners = [137112412989]
    filter {
        name = "name"
        values = [var.image_name]
      
    }

}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.amazon.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-public-subnet.id
    security_groups = [aws_security_group.myapp-sg.id]
    availability_zone = var.availa_zone_public
    associate_public_ip_address = true
    key_name = "linux testing-1"

    user_data = file("env-script.sh")

    tags = {
     Name = "${var.env_prefix}-server"
  }
}