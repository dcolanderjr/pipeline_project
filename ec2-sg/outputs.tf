output "jenkins-master-public-ip" {                            // output block for public ip
    value = aws_instance.jenkins-master.public_ip
}

output "jenkins-agent-public-ip" {                            // output block for public ip
    value = aws_instance.jenkins-agent.public_ip
}

output "eip_master" {                            // output block for elastic ip
    value = aws_eip.jenkins-master.public_ip
}

output "eip_agent" {                            // output block for elastic ip
    value = aws_eip.jenkins-agent.public_ip
}
output "instance_id_master" {                         // output block for instance id
    value = aws_instance.jenkins-master.id
}

output "instance_id_agent" {                         // output block for instance id
    value = aws_instance.jenkins-agent.id
}

output "public_ipv6_master" {
    value = aws_instance.jenkins-master.ipv6_addresses
}

output "public_ipv6_agent" {
    value = aws_instance.jenkins-agent.ipv6_addresses
}
