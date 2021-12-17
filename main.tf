locals {
  vpc_id           = "vpc-0133a694a16788eb8"
  subnet_id        = "subnet-0282382fe5d2cb2f1"
  ssh_user         = "ubuntu"
  key_name         = "aws_key1"
  private_key_path = "aws_key1"
  ami              = "ami-04505e74c0741db8d"
  instance_type    = "t2.micro"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "nginx" {
  name   = "nginx_access"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

resource "aws_key_pair" "deployer" {
  key_name = "aws_key1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/KuAYTjcsCAB2KY6IAFbc1ny8lMr8ClB7tycvc5ePCwNDw99yJUpyx95s9HT9aZrtiI7olePLR6lCxjTkpKbp5naX1fj1+lR0Jw1zjAhkadFx8ldGdY9onZxB/EB0O5tItmpZ+GRaiSk6uqDRpBYRhuDvHKPWX+6roC7L8qhEgy/Z7c1obi6C5J13mWppyTHWk3xTqB+9F99T8NABlmi3NPPiyXinRW5s903//czHpZpRQSAQUOpv5Jxa78m1nVS2R2q6ewNLanZz/VuWWb8vNxF21w17d5NfssP2oRYoKyY4xJKxBN+d+Pb7AQHv0/AEnmimvpuWQjhw80IEUiVINIDyFIdNOl8hl55IU+rmcCCKsZki4RdBtqx/hcS0VV4UxhB3H84dXEfkv0mPf+hQhcowxTyfQM+r34aAOYXIKEnAPjObfZqv1bIIXzVDa78NncFa5Tjq+3AJFcNRl8ej1RMd42t/sTrKuE0rl0hdc1vT5M0frPywOXfqyUTJ3CU= ubuntu@ip-172-31-2-245"
}

resource "aws_instance" "nginx" {
  ami                         = local.ami
  subnet_id                   = local.subnet_id
  instance_type               = local.instance_type
  associate_public_ip_address = true
  security_groups             = [aws_security_group.nginx.id]
  key_name                    = local.key_name

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = aws_instance.nginx.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.nginx.public_ip}, --private-key ${local.private_key_path} nginx.yaml"
  }
}

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}