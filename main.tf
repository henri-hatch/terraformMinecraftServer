provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "minecraftserver" {
  ami                         = "ami-09d95fab7fff3776c"
  instance_type               = "t2.large"
  associate_public_ip_address = true
  key_name                    = "minecraftserver"
  iam_instance_profile        = "s3AdminAccess"
  tags = {
    Name = "minecraft"
  }
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("C:/Users/henri/Documents/PEM/minecraftserver.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "aws s3 cp s3://minecraft-terraform-files/ . --recursive",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "aws s3 cp . s3://minecraft-terraform-files/ --recursive"
    ]
  }
}

resource "aws_route53_record" "minecraft_record" {
  zone_id = "Z1KMSJTSFH7XB"
  name    = "minecraft.hatchhome.com"
  type    = "A"
  ttl     = "30"
  records = [aws_instance.minecraftserver.public_ip]
}