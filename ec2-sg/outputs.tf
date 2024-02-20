# Purpose: This file contains the output block for the 
# terraform resources created in the main.tf file. 
# The output block is used to display the public ip, 
# instance id and elastic ip of the jenkins master and agent instances
# sonarqube and eks-bootstrap-server instances.
# The public ip and instance id are used to connect to the instances and 
# the elastic ip is used to associate the public ip with the instances. 
# The public ipv6 address is also displayed in the output block.
output "jenkins-master-public-ip" {                            // output block for public ip
    value = aws_instance.jenkins-master.public_ip
}

output "jenkins-agent-public-ip" {                            // output block for public ip
    value = aws_instance.jenkins-agent.public_ip
}

output "sonarqube-public-ip" {                            // output block for public ip
    value = aws_instance.sonarqube.public_ip
}

output "eks-bootstrap-server-public-ip" {                            // output block for public ip
    value = aws_instance.eks-bootstrap-server.public_ip
}

output "eip_master" {                            // output block for elastic ip
    value = aws_eip.jenkins-master.public_ip
}

output "eip_agent" {                            // output block for elastic ip
    value = aws_eip.jenkins-agent.public_ip
}

output "eip_sonarqube" {
    value = aws_eip.sonarqube.public_ip
}

output "eip_eks-bootstrap-server" {
    value = aws_eip.eks-bootstrap-server.public_ip
}
output "instance_id_master" {                         // output block for instance id
    value = aws_instance.jenkins-master.id
}

output "instance_id_agent" {                         // output block for instance id
    value = aws_instance.jenkins-agent.id
}

output "instance_id_sonarqube" {
    value = aws_instance.sonarqube.id
}

output "instance_id_eks_bootstrap_server" {
    value = aws_instance.eks-bootstrap-server.id
}
output "public_ipv6_master" {
    value = aws_instance.jenkins-master.ipv6_addresses
}

output "public_ipv6_agent" {
    value = aws_instance.jenkins-agent.ipv6_addresses
}

output "public_ipv6_sonarqube" {
    value = aws_instance.sonarqube.ipv6_addresses
}

output "public_ipv6_eks_bootstrap_server" {
    value = aws_instance.eks-bootstrap-server.ipv6_addresses
}