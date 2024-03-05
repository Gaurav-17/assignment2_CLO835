data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}


resource "aws_instance" "k8s" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"

  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo usermod -a -G docker ec2-user
    sudo systemctl restart docker
    curl -sLo kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
    sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
    rm -f ./kind
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f ./kubectl
    echo -e 'kind: Cluster\napiVersion: kind.x-k8s.io/v1alpha4\nnodes:\n- role: control-plane\n  image: kindest/node:v1.19.11@sha256:07db187ae84b4b7de440a73886f008cf903fcf5764ba8106a9fd5243d6f32729\n  extraPortMappings:\n  - containerPort: 30000\n    hostPort: 30000\n  - containerPort: 30001\n    hostPort: 30001' > /home/ec2-user/kind.yaml
  EOF

  vpc_security_group_ids = [
    module.ec2_sg.security_group_id,
    module.dev_ssh_sg.security_group_id
  ]
  iam_instance_profile = "LabInstanceProfile"

  tags = {
    project = "clo835"
  }

  key_name                = "ass2"
  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = true
}


resource "aws_key_pair" "k8s" {
  key_name   = "ass2"
  public_key = file("${path.module}/ass2.pub")
}