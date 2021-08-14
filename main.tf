provider "aws" {
region = "us-east-1"
}


#############################vpc##################################


resource "aws_vpc" "my_vpc" {
cidr_block = "10.0.0.0/16"
instance_tenancy = "default"
tags = {
Name = "my-vpc"
}
}


#################subnets##########################################


resource "aws_subnet" "public-subnet" {

cidr_block = "10.0.1.0/24"
vpc_id = aws_vpc.my_vpc.id
tags = {
Name = "public subnet"
}
}


resource "aws_subnet" "private-subnet" {

cidr_block = "10.0.2.0/24"
vpc_id = aws_vpc.my_vpc.id
tags = {
Name = "private subnet"
}
}





#################################security group################################




resource "aws_security_group" "my-sg" {
  name        = "my-sg"
  description = "security group for project"
  vpc_id      = aws_vpc.my_vpc.id

  ingress  {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  tags = {
    Name = "my-sg"
  }
}





##############################igw####################################################3333

resource "aws_internet_gateway" "myigw" {
vpc_id = aws_vpc.my_vpc.id
tags = {
Name = "myigw"
}
}




###############################################route table#####################################################
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myigw.id
    }

  tags = {
    Name = "public route table"
  }
}





##############################route table association#######################################

resource "aws_route_table_association" "public-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}




####################################key-pair############################################

resource "aws_key_pair" "mykey" {
key_name   = "project-key"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbAS1dpkWc+31oq8/cfjODDCz85skaLm4tItNrCRjtnDeCOyFiEwUoggcdXk1hlywj0uL/QTkG6zLFfaviy2ZudHSLBzOFd2omfuApeFVl6Gz+uYZB0n3C863cHRn45WkSSgDqrmcJ88jpt/e9qXyY+TV+Em2mKvbwJ3tyqZFWwMz4owTWc1+hGSXWjG1l+dzu2/xHt3w62IERFr0mqlW6/sq8/U5A8jf4sU3AVxhzqtYm2vpCL16qZoESswIhJZtvivKWeKK+d84cMnDfvwE+pWQTEvq4hGvz52jn8d70Ynn2wZtix5lQmL3FoQ15O1xZUEopTAPrBft1kh6QU6YP root@ip-172-31-38-45.ec2.internal"


}

########################################################web-instance#############################

resource "aws_instance" "web" {
ami = "ami-0c2b8ca1dad447f8a"
instance_type = "t2.micro"
key_name = "project-key"
tags = {
Name = "web-server"
}
subnet_id = aws_subnet.public-subnet.id
vpc_security_group_ids = [aws_security_group.my-sg.id]

}


resource "aws_eip" "my-eip" {
instance =aws_instance.web.id
vpc =true
}



########################################################database-instance##########################


resource "aws_instance" "db" {
ami = "ami-0c2b8ca1dad447f8a"
instance_type = "t2.micro"
key_name = "project-key"
tags = {
Name = "db-server"
}
subnet_id = aws_subnet.private-subnet.id
vpc_security_group_ids = [aws_security_group.my-sg.id]

}



##########################nat gateway################################################33333
resource "aws_nat_gateway" "mynat" {
  subnet_id     = aws_subnet.public-subnet.id
 allocation_id = aws_eip.nat-eip.id
  tags = {
    Name = "myNAT"
  }


}


resource "aws_eip" "nat-eip" {
vpc =true
}



################################route table for nat gateway#################################


resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.mynat.id
    }

  tags = {
    Name = "private route table"
  }
}




##############################route table association#######################################

resource "aws_route_table_association" "private-association" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}
