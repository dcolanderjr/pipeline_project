# pipeline_project

This project showcases some very important DevOps tools. It features a Jenkins Master/Agent configuration. The build artifacts for the application go through Maven.

The Terraform code provided creates the infrastructure for the EC2 instances on AWS that you need to create the Master-Agent tandem. Note: elastic IP's are not needed, I just used them however for this project. Reason being, is you are charged for EIP's even if you do not use them, so this is something you definitely do not want to leave up long. Plus, if I decided to shut down my instance for any reason during the project, I did not want to go through the hassle of having to reconfigure anything that relied on the public IP.


