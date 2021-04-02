variable "common_tags" {
  type = map(string)
  default = {
    "Description" : "Frontend Infra",
    "Owner" : "APP Team"
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "frontend_instance_count" {
  default = 1
}

variable "frontend_instance_type" {
  default = "t2.micro"
}


