resource "aws_security_group" "web_sg" {
    name = "web-sg"
    description = "allow HTTP traffic"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
   
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

resource "aws_instance" "web" {
  ami                    = "ami-0c2ab3b8efb09f272" # Amazon Linux 2 (us-west-2)
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("../scripts/install_nginx.sh")

  tags = {
    Name = "self-healing-web"
  }
}
