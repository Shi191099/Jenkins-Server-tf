resource "aws_security_group" "mysg" {
depends_on = [aws_vpc.myvpc, aws_subnet.mysubnet]
name        = "MySG for Master & Slave"
description = "Allow port no. 22"
vpc_id      = aws_vpc.myvpc.id

ingress {
   description = "allow SSH"
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

  ingress {
     from_port   = 6443
     to_port     = 6443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

egress {

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Name = "My_SG"
}
}

resource "aws_instance" "Master" {
depends_on = [aws_security_group.mysg]
subnet_id = aws_subnet.mysubnet.id
ami           = "ami-0c2ab3b8efb09f272"
associate_public_ip_address = true
instance_type = "t2.micro"
key_name = "tf"
vpc_security_group_ids = [ aws_security_group.mysg.id ]


metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 20
     http_tokens = "optional"
    instance_metadata_tags = "enabled"
  }

tags = {
Name = "JenkinsMaster"
}
}

resource "local_file" "ipaddr" {
    
 filename = "./inventory.txt"
 content = <<-EOT
     [JenkinsMaster]
     ${aws_instance.Master.public_ip}
   EOT
 }


 resource "null_resource" "nulllocal3"{
   depends_on = [local_file.ipaddr] 

 provisioner "local-exec" {
         command     = "ansible-playbook /home/ansible/JenkinsServer/Ansible/jenkins_ansible.yml"
     }
 }

