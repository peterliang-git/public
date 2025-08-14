variable "ec2_instance_name"{
    description = "EC2 instance name tag"
    type = string
    default = "MyNewInstance"
}

variable "ec2_instance_type"{
    description = "EC2 instance type"
    type = string
    default = "t2.micro"
}

variable "ec2_ami"{
    description = "EC2 AMI"
    type = string
    default = "ami-0de716d6197524dd9"
}

variable "vpc_name"{
    description = "VPC name"
    type = string
    default = "MyTestVPC"
}
variable "vpc_cidr"{
    description = "VPC CIDR"
    type = string
    default = "10.0.0.0/16"
}

variable "subnet_name"{
    description = "SubNet name"
    type = string
    default = "MyTestSubnet"
}
variable "subnet_cidr"{
    description = "Subnet CIDR"
    type = string
    default = "10.0.1.0/24"
}

variable "igw_name"{
    description = "IGW name"
    type = string
    default = "MyTestIGW"
}

variable "rtb_name"{
    description = "Route table name"
    type = string
    default = "MyPublicRouteTable"
}