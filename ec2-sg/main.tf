resource "aws_instance" "ec2" {     // resource block for ec2 instance
    ami = ami-0c7217cdde317cfec
    instance_type = t2.micro
    key_name = "Terraform"

    tags = {                        // tags block for ec2 instance 
        Name = "Jenkins-Master"
        Terraform = "true"
        Environment = "dev"
        Project = "CI/CD"
    }
}

resource "ebs_volume" "ebs" {       // resource block for ebs volume
    availability_zone = "us-east-1a"
    type = "gp2"
    encrypted = false
    size = 20
    tags = {
        Name = "Jenkins-Volume"
        Terraform = "true"
        Environment = "dev"
        Project = "CI/CD"
    }
}

resource "aws_volume_attachment" "ebs" {    // resource block for ebs volume attachment
    device_name = "/dev/sdh"
    instance_id = aws_instance.ec2.id
    volume_id = ebs_volume.ebs.id
}

resource "security_group" "jenkins" {       // resource block for security group
    name = "jenkins"
    description = "Ingress_Egress_Rules"
    vpc_id = "vpc-036bb8c5486c280db"
    subnet_id = "subnet-0f956e05674fada38"
    
    ingress {                               
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        description = "Allow Jenkins"
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        description = "Allow SSH"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        description = "Allow all outbound traffic"
    }
}

output "public_ip" {                            // output block for public ip
    value = aws_instance.ec2.public_ip
}

output "private_ip" {                           // output block for private ip
    value = aws_instance.ec2.private_ip
}

output "instance_id" {                         // output block for instance id
    value = aws_instance.ec2.id
}
