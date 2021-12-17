## <u>Step 1:</u>

Log in to AWS account.

## <u>Step 2:</u>

Create a VPC.

## <u>Step 3:</u>

Create a Subnet for the VPC.

## <u>Step 4:</u>

Create Internet Gateway.

## <u>Step 5:</u>

Attach Internet Gateway to the VPC.

## <u>Step 6:</u>

Add a IGW route in the route table for the subnet.

## <u>Step 7:</u>

Clone this repository
```sh
git clone https://github.com/kapilkumaria/masterclass-terraform-ansible-integration.git
```
```sh
cd masterclass-terraform-ansible-integration
```
## <u>Step 8:</u>

Create a SSH Key
```sh
ssh-keygen                 # Creating SSH Key pair
cp ~/.ssh/id_rsa* .        # Moving the new SSH Keys to the current folder
mv id_rsa aws_key          # Changing name for SSH private key
mv id_rsa.pub aws_key.pub  # Changing name for SSH public key
chmod 400 aws_key          # Ensure your key is not publicly viewable
```
## <u>Step 9:</u>

Modify "main.tf" terraform code

```sh
locals {
  vpc_id           = "vpc-xxxxxxxxxxxxx"               # Use vpc_id from Step-2
  subnet_id        = "subnet-xxxxxxxxxxxxxxxxxxx"      # Use vpc_id from Step-3
  ssh_user         = "ubuntu"                        
  key_name         = "aws_key"
  private_key_path = "aws_key"
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
  public_key = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  # Use aws_key.pub contents from Step-8
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
```
## <u>Step 10:</u>

Run Terraform code
```sh
terraform init
terraform plan
terraform apply
```
## <u>Step 11:</u>

- Test the newly created server for Nginx application
- Grab the "Public-IP" of the instance and paste in the browser
- Success - able to see the Nginx homepage