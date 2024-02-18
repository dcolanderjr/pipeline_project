This project just showcases a demo CI/CD pipeline using some common DevOps tools. Included in this project is Terraform for IaC, for deploying our instaneces to the AWS environment. Jenkins for our CICD pipeline. Maven for storing build artificats. SonarQube for continuous code inspection. Docker for 

Note: alot of this configuration is going to be trial and error, and just as the last project, I am going to intentionally leave some instructions out so that you can troubleshoot. Troubleshooting is part of the process, and it makes your learning experience much more satisfying once something works. Believe me, I had to troubleshoot while doing this, so I have to share the pain. =D

Prerequisites:
1: You will need an AWS account. You will need access to a user who can create IAM roles, and give the proper permissions. The IAM role that will be created for the Jenkins server needs to just have programmatic access, nothing more. Create a user, CICD-Project (or whatever) and delegate them access rights as you see fit, but they must have programmtic access. Note: you only get one shot to look at your access keys, so throw it in a notepad for later.

2: A code editor. I use VSCode, but you can use what you like. You will need to configure VSCode with your AWS programmtic keys in order to push the Terraform infrastructure. (Alternatively, you can just launch your instances in the Console, which is fine. Just know, I have not made the instructions for the console (yet, maybe?) 

3: A Github account. You can perform this in whatever source code repository you use, just be aware that the instructions will be for github.

4: A Docker account. It is free, and you will need to generate a token for our project. To generate a token, go to MyAccount > Security, and follow the instructions in order to get an access token. Note: Just like AWS, you only get one shot to look at it and take it down, so my advice is throw it in a notepad.

5: An SSH agent. If you want, you can use EC2 instance connect to connect, and configure your instances, or you can use PuTTy(Windows)/MobaXterm or the native shells on Mac/Linux.

Infrastructure Configuration - For this project, we will need 3 instances; you can technically do this with two, but the SonarQube instance uses alot of resources. I have tried it with two, one t2.micro for the Jenkins-Agent, and a t2.medium(or t2.large) for the SonarQube/Jenkins-Master instance. The Jenkins-Agent can use 15-20GB of EBS, but the t2.medium will need at least 45-55GB of EBS storage space. This costs money, some of this is in the free tier, but most of it will cost a few dollars to run, especially if you do this over a couple of days. No, it will not break the bank, maybe 5-10 bucks. I used EIP's just for the fact that I shut down my instances when I was not working on this, just to save a little bit. The included modules for Terraform have it set up as 3 instances, it includes EIP's, the security group configuration, and some outputs for future use, or if you want to be a little more advanced. Make sure you verify the AMI id of the instances against the console as these are updated regularly, and change your region if you wish to do so. Also, go into the console, on the left hand side, create a key-pair for your EC2 instances. You will need this to SSH into the instances to configure them. 



Jenkins Configuration - 



SonarQube Configuration - 



Docker Configuration - on the jenkins configuration page navigate to plugins, and download the following and install them on your jenkins server. On the next page where it shows downloading, make sure to tick the box that says reboot after installation. Once you reboot, you may be required to log back in.
![image](https://github.com/dcolanderjr/pipeline_project/assets/131455625/79c11563-0a74-4be9-bd44-9d573449bd3a)

Once you perform this task
