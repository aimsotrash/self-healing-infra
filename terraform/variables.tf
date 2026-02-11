variable "region" {
    description = "Aws region to deploy in"
    type = string
    default = "us-west-2"
}

variable "instance_type" {
    description = "EC2 Instance Type"
    type = string
    default = "t3.micro"
}