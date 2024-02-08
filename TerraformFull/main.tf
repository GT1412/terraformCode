provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "gt_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "gt_vpc"
  }
}

resource "aws_subnet" "gt_pub_subnet" {
  vpc_id                  = aws_vpc.gt_vpc.id
  cidr_block              = var.cidr_block_subnet
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "gt_pub_subnet"
  }
}


resource "aws_internet_gateway" "gtigw" {
  vpc_id = aws_vpc.gt_vpc.id

  tags = {
    Name = "gtigw"
  }
}

resource "aws_security_group" "gtsg" {
  vpc_id = aws_vpc.gt_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.cidr_block_internet
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    // This means, all ip address are allowed to ssh ! 
    // Do not do it in the production. 
    // Put your office or home address in it!
    cidr_blocks = var.cidr_block_internet
  }
  //If you do not add this rule, you can not reach the NGIX  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_block_internet
  }
  tags = {
    Name = "gtsg"
  }
}

resource "aws_route_table" "gt_pub_rt" {
  vpc_id = aws_vpc.gt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gtigw.id
  }

  tags = {
    Name = "gt_pub_rt"
  }
}


resource "aws_route_table_association" "gt_pub_rta" {
  subnet_id      = aws_subnet.gt_pub_subnet.id
  route_table_id = aws_route_table.gt_pub_rt.id
}

resource "aws_key_pair" "gt_key_pair" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/GUjTQiWQMMR01c6tjLabyNSKgNtActK/pCdhBfv8gqGBQ6fqzxkg/go7vSGWEWL7Edacg2uQvL8qpnazLdwolCRQeLo7njKwSF5n+gQy+JCSkFIPmRxdtd3g3eYKDovwy5TFK5AXymHiA7ifZbEK5DrNPxcpkLUrpD5oReFNgEaoDBMwcBSbN8suachZEZw/Qx0GNLDDrz3iNGMVb8txU2kwBvNZb/KJ3203qF6HurN0NDie4wNhc+uXv8aAmkWNvDVgtdGlC/6ivXpXG1qa+/0ocZLSTyGyJoqcKLlrHx5demby35s2GDe/lBKvIyHhPxws7hr5r6LCPS6H+PuSdt6i38Wntl4BWFtpFo1qkGX9dJauS4aXUax8ZP4kMzlJVM6RL/fOR6a/pIl1qwYVOyIaBovPbJe/D2YXfGOGXn6Ur2KaJ4G8fSkgAk0XLlH6N7yIE2IAYrKP8qyXNJjgoH0mTuh5fdV1pr+yobr4aiCh9oVNw57WIo3XYfkYOzE= gaurav@localhost.localdomain"
}

resource "aws_instance" "gt_vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = "id_rsa"
  security_groups        = [aws_security_group.gtsg.id]
  vpc_security_group_ids = [aws_security_group.gtsg.id]
  subnet_id              = aws_subnet.gt_pub_subnet.id

  tags = {
    Name = "gt_vm"
  }
  provisioner "file" {
    source      = "./index.html"
    destination = "/tmp/index.html"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo cp /tmp/index.html /var/www/html/",
      "sudo systemctl restart httpd"
    ]
  }
  connection {
    host        = self.public_ip
    user        = "ec2-user"
    type        = "ssh"
    private_key = file("./id_rsa")
  }
}


# terraform graph for the see graphical user interface
# terraform graph > dot



# terraform  course
# https://github.com/stacksimplify/hashicorp-certified-terraform-associate