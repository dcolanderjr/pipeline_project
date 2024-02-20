This project showcases a CI/CD pipeline. Starts out by a user uploading their code to Github, which will be pulled into Jenkins. After it is pulled into Jenkins, it'll be built and tested through Maven, and SonarQube respectively. After that, a Docker image will be created, and sent through Trivy for package scanning. This is the CI part of the pipeline. Afterwards, CD will start in which the manifest file will be created and sent back into GitHub. At that point, ArgoCD will pull the upgraded K8 manifest files and deploy them on EKS.
A webhook will tie it all together, so that each time there is a git commit that updates the web application, it will automatically create a build pipeline for continuous delivery.

To get started, download the repo, have a review of the files there, and lets get to it.

Prerequisites:
1: You will need an AWS account. You will need access to a user who can create IAM roles, and give the proper permissions. The IAM role that will be created for the Jenkins servers, the Kubernetes server: it needs to just have programmatic access, nothing more. Create a user, CICD-Project (or whatever) and delegate them access rights as you see fit, but they must have programmtic access. Note: you only get one shot to look at your access keys, so throw it in a notepad for later.

2: A code editor. I use VSCode, but you can use what you like. You will need to configure VSCode with your AWS programmtic keys in order to push the Terraform infrastructure. (Alternatively, you can just launch your instances in the Console, which is fine. Just know, I have not made the instructions for the console (yet, maybe?)) 

3: A Github account. You can perform this in whatever source code repository you use, just be aware that the instructions will be for github. You will need a GitHub token, this can be found under Settings > Developer Settings > Personal Access Token. Create two, and save them in a scratch pad, you will need these for later: one for ArgoCD and one for Jenkins.

4: A Docker account. It is free, and you will need to generate a token for our project. To generate a token, go to MyAccount > Security, and follow the instructions in order to get an access token. Note: Just like AWS, you only get one shot to look at it and take it down, so my advice is throw it in a notepad.

5: An SSH agent. If you want, you can use EC2 instance connect to connect(or Systems Manager), and configure your instances, or you can use PuTTy(Windows)/MobaXterm or the native shells on Mac/Linux., ppk and pem files respectively.

An intermediate level of linux commands will necessary for this as most of this is performed in the command line. I will provide a few of the commands, but most of this can be found online.

Infrastructure Configuration: I used four instances in this project. One for the Jenkins-Master, one for the Jenkins-Agent, one for SonarQube, and one for EKS. You can however complete this with 2 or 3 (I've tried with three, just need to use larger instances/EBS volumes for storage.) You could also use a Fargate cluster to deploy Kubernetes since this is just a small web application, however, for the sake of this project, I will assume you have used four. 

Note: if you do not complete this in one go, make sure you stop your instances. I used EIP's so my instances would not use their public IPs if I stopped and came back to it later. The t2.micro instances are in the free tier, however the t3.medium I used is outside of the free tier. Also, you are billed for hourly usage on your EIPs, plan accordingly.

Infrastructure configurations & necessary downloads: The included shell script should get you started with a few things, but explore the internet and use your resources for the necessary downloads. In VSCode, make sure you download Terraform, and Github. You will need Terraform to deploy the infrastructure (optional) but you will need Github to push your source code. I would assume you know what Terraform init, plan and apply are, if not, use the console, if necessary to launch your instances. But I would encourage you to give it a go, and learn.

Jenkins Master - The master instance is in the ec2-sg > main.tf file: the instance is configured with 20GB of EBS space, an EIP, and some tags. Feel free to edit them as you need to.
Required Downloads - openJDK-17-jre, docker, jenkins

Jenkins Agent - The agent instance is in the ec2-sg > main.tf file: the instance is configured with 20GB of EBS space, an EIP, and some tags. Feel free to edit them as you need to.
Required Downloads - openJDK-17-jre, docker, jenkins, maven, Trivy

SonarQube - The sonarqube instance is in the ec2-sg > main.tf file: the instance is configured with 20GB of EBS space, an EIP, and some tags. Feel free to edit them as you need to.
Required Downloads - openJDK-17-jre, docker, sonarqube, postgresql

EKS-Bootstrap-Server
Required Downloads - Docker, ArgoCD, kubectl

... included in the repo is the Terraform configuration to get you started. It will launch Jenkins-Master, Jenkins-Agent, SonarQube, and EKS instance. When you launch each instance, make sure you run the apt commands to update, and upgrade prior to starting any other downloads. The instances will launch with the necessary ports open, so you should not have to mess with your security group rules, however, double check in the console. Note: Make sure you change the region, subnet ID's if you are using the Terraform template, they can be launched, however, they are more of a guide in order to let you know what the configuration is. If you want to use the console, you can skip this part of using Terraform, manually create your instances, and pick up below. I do however encourage you to navigate through completing the infrastructure as code portion, as this is just more practice. There is ALSO a Jenkins file that has the full pipeline already configured, you will need to update this information with YOUR information as we go. The project is iterative. I am assuming you have a bit of know how, and you test your build as we go along, comment out the parts we do not need and unlock them as we go along. There is some jumping back and forth, so please be aware of which repo I am directing you to. The Jenkinsfile in the 'pipeline-project' is the one that is iterative, and you should be following along, the second one in 'gitops-pipeline-app' is the secondary one. ...

Jenkins-Master Configuration:
Using your SSH tool, login to the instance using its public IP address and the keypair you created earlier. Then run the following commands:
. sudo apt update
. sudo apt upgrade
. sudo nano /etc/hostname >> change the hostname to 'Jenkins-Master' // save and exit. :wq!
. sudo init 6 (this should reboot your server, wait about 20-30 seconds, and reconnect via SSH)
. sudo apt install openjdk-17-jre
. java --version // verify you have downloaded Java
. sudo apt-get install docker.io
. sudo usermod -aG docker $USER
. sudo init 6 (this should reboot your server, wait about 20-30 seconds, and reonnect via SSH, alternatively use newgrp docker command)
Next, navigate to your browser, and search for "Jenkins weekly release", navigate to the section for Ubuntu, and copy the script to download and install Jenkins.
. sudo systemctl start jenkins
. sudo systemctl enable jenkins
. sudo systemctl status jenkins
. sudo nano /etc/ssh/sshd_config
In this file, uncomment PubkeyAuthentication yes AND AuthorizedKeysFile, save and close. 
. ssh-keygen
This will generate an SSH key that you will need to configure on the Jenkins-Agent in the next set of instructions. This should generate a keygen image:

![Screenshot 2024-02-20 101632](https://github.com/dcolanderjr/pipeline_project/assets/131455625/b35c459e-b845-486c-9d08-071670753f5b)

. cd .ssh/
You should see three files, if you are using MobaXterm, navigate using the folders on the left hand panel, otherwise use the 'cat id_rsa_pub' to read the file, copy its contents, you will need them later.

Jenkins-Agent Configuration
Using your SSH tool, login to the instance using its public IP address and the keypair you created earlier.
Then run the following commands (ENSURE DOCKER IS INSTALLED HERE, IT WILL BE USED TO BUILD EVERYTHING):

. sudo apt update
. sudo apt upgrade
. sudo nano /etc/hostname >> change the hostname to 'Jenkins-Agent' // save and exit. :wq!
. sudo init 6 (this should reboot your server, wait about 20-30 seconds, and reconnect via SSH)
. sudo apt install openjdk-17-jre
. java --version // verify you have downloaded Java
. sudo apt-get install docker.io
. sudo usermod -aG docker $USER
. sudo init 6 (this should reboot your server, wait about 20-30 seconds, and reonnect via SSH, alternatively use newgrp docker command)
Next, navigate to your browser, and search for "Jenkins weekly release", navigate to the section for Ubuntu, and copy the script to download and install Jenkins.
. sudo systemctl start jenkins
. sudo systemctl enable jenkins
. sudo systemctl status jenkins
. sudo nano /etc/ssh/sshd_config
In this file, uncomment PubkeyAuthentication yes AND AuthorizedKeysFile, save and close. 
. sudo service sshd reload
Perform this on both instances.
. cd .ssh/
You should see an authorized_keys file, from that last step in the 'Jenkins-Master' node section, paste in your
ssh key UNDER the existing one. DO NOT OVERWRITE THE EXISTING KEY. You can use vim or nano if you are not using MobaXterm. Once complete, ensure you run 'cat authorized_keys' to ensure you have completed this step.

Next, copy the public IP of the Jenkins-Master node, and use your web browser to access Jenkins. Make sure you append port 8080 on the end ie. :8080 to whatever the IP address is. This will allow you to access Jenkins. Now, what you need to do is return to the Jenkins-Master ssh terminal, run the following command to get the initial password:
. sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Copy and paste that into the Unlock Jenkins page. Install suggested plugins. Create a user, and a new password. You will use this to log in to Jenkins going forward, save and continue through finish to start using Jenkins.

Configure Jenkins-Agent as a node
From the Dashboard > Manage Jenkins > Nodes > Built-in Node > Configure
Number of executors = 0, save

Dashboard > Manage Jenkins > Nodes > New Node
Enter Jenkins-Agent, click tick for permanent agent, create.
Name                 = Jenkins-Agent
Number of executors  = 2
Remote root director = /home/ubuntu
Labels               = Jenkins-Agent
Usage                = Use this node as much as possible
Launch method        = Launch agent via SSH
Host                 = Paste private IP (if same VPC), public (different VPC)
Credentials          = Add > 
                       Kind         = SSH Username w/ private key > 
                       ID           = Jenkins-Agent > 
                       Description  = Jenkins-Agent
                       Username     = Ubuntu
                       Private Key  = Enter Directly, return to the Jenkins-Master 'cat id_rsa' copy the entire key, click add, and paste in the box, click add.
                       Credentials  = select the created key
Host Key Verfication = Non verifying verification strategy
Save.

Return to the dashboard, click on New Item on the left hand side. We are going to create a test pipeline to test connectivity to our builder node. Name it 'Test', click on 'Pipeline' and then click ok.
Scroll to the bottom, and in the pipeline box, choose the 'Hello World' script from the drop down box, select it, apply, and save.

On the following screen, click the Build Now button, you should get this:

![TestPipeline](https://github.com/dcolanderjr/pipeline_project/assets/131455625/d7909ed5-557a-458e-b40c-8b8ad6a49b39)

Next, we will configure the plugins that we are going to need. Navigate to Dashboard > Manage Jenkins > Plugins. Install the following plugins: Maven Integration, Pipeline Maven Integration, Eclipse Temurin Installer. Configure the plugins now. Make sure you use the names provided in the screenshots, they will be referenced in the pipeline script.

Navigate to Dashboard > Manage Jenkins > Tools 

![maveninstall](https://github.com/dcolanderjr/pipeline_project/assets/131455625/866dff4d-82a6-4ac8-bef0-690964bfebf6)

![javascriptinstallation](https://github.com/dcolanderjr/pipeline_project/assets/131455625/9b4a9e40-9f7e-4479-b203-23b43e2bf90a)



Next, return to the Dashboard. Manage Jenkins > Credentials > System > Global credentials (unrestricted). If you have not alreday created your access token in github, do that now. Your password is your access token. The ID for this will be 'github' which is referenced in the Jenkinsfile script used later.

![credentials](https://github.com/dcolanderjr/pipeline_project/assets/131455625/ccf8f9c8-1899-40ba-b26a-22e184bd5b11)


Next, will configure the SonarQube Instance, you will need to SSH into the instance in order to configure it. The SonarQube instance is the t3.medium, again, the reason why this one is used is because of the database (PostgreSQL) and SonarQube. I am going to just leave the instructions on this portion. This part is not difficult, however, some of the learning pains I had doing this came from this section here.

. Perform Updates
. sudo apt update
. sudo apt upgrade
. sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/      sources.list.d/pgdg.list'
. wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null

Install PostgreSQL

. sudo apt update
. sudo apt-get -y install postgresql postgresql-contrib
. sudo systemctl enable postgresql

Create Database for Sonarqube
. sudo passwd postgres (IMPORTANT, YOU WILL NEED TO REMEMBER THIS PASSWORD)
. su - postgres
. createuser sonar 
. psql 
. ALTER USER sonar WITH ENCRYPTED password 'sonar';
. CREATE DATABASE sonarqube OWNER sonar;
. grant all privileges on DATABASE sonarqube to sonar;
. \q
. exit

Add the repository for Adpotium (Important)
. sudo bash
. wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
. echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

Install Java 17
. apt update
. apt install temurin-17-jdk
. update-alternatives --config java
. /usr/bin/java --version
. exit 

Linux Kernel Tuning - SonarQube uses alot of resources, and we need to tune some of the kernel files. Below are the files, and what should be added into the files. It is EXTREMELY important that you do not modify ANYTHING else except what is asked of you below. Copy and paste the information at the end of the file, and then save and quit.

. sudo vim /etc/security/limits.conf (IMPORTANT STEP, DO NOT SKIP)
    Paste the below values at the bottom of the file
    sonarqube   -   nofile   65536
    sonarqube   -   nproc    4096

Increase Mapped Memory Regions - Long story short, elastisearch which is by SonarQube to find the vulnerabilties moves very fast to reference and cross reference from the DB, its imperative that we give it enough memory to do so, efficiently. Below this value, is not recommended.

. sudo vim /etc/sysctl.conf (IMPORTANT STEP, DO NOT SKIP)
    Paste the below values at the bottom of the file
    vm.max_map_count = 262144

Install SonarQube

. sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip
. sudo apt install unzip
. sudo unzip sonarqube-9.9.0.65466.zip -d /opt
. sudo mv /opt/sonarqube-9.9.0.65466 /opt/sonarqube

Create user and set permissions - This section will create the sonarqube user, and password that will be needed to login, use the defaults listed below, change it once you can access it if you desire.

. sudo groupadd sonar
. sudo useradd -c "user to run SonarQube" -d /opt/sonarqube -g sonar sonar
. sudo chown sonar:sonar /opt/sonarqube -R

Update Sonarqube properties with DB credentials
     
. sudo vim /opt/sonarqube/conf/sonar.properties
    
     sonar.jdbc.username=sonar
     sonar.jdbc.password=sonar
     sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

![sonarqubedbsettings](https://github.com/dcolanderjr/pipeline_project/assets/131455625/b9f29c6f-f5e4-4121-8cb0-967d564336b3)


Create the SonarQube Service. You will need to create this file, it is empty. And copy and paste the information below into it. Then save and quit.

. sudo vim /etc/systemd/system/sonar.service

   Copy the information below, and paste it into the above file location.
     [Unit]
     Description=SonarQube service
     After=syslog.target network.target

     [Service]
     Type=forking

     ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
     ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

     User=sonar
     Group=sonar
     Restart=always

     LimitNOFILE=65536
     LimitNPROC=4096

     [Install]
     WantedBy=multi-user.target

Start Sonarqube and Enable service
. sudo systemctl start sonar
. sudo systemctl enable sonar
. sudo systemctl status sonar

Watch log files and monitor for startup

. sudo tail -f /opt/sonarqube/logs/sonar.log

If everything went well, you should have been presented with this page upon login:

![sonarqubewelcome](https://github.com/dcolanderjr/pipeline_project/assets/131455625/84ec2670-0779-4aaf-89d4-ffca47c3ab1e)



Next, we now need to integrate SonarQube with Jenkins. Click on the 'A' in the upper right hand corner > My Account > Security > Generate Token 

Name = jenkins-sonarqube-token
Type = Global Analysis Token
Expiration = 30 days

Important Note: You only get one shot for this token, so make sure you copy and paste it and throw it in a scratch pad. You will need this to integrate it with Jenkins.

Now, move back over to Jenkins, and add the credentials. We did this in a previous step, so you should be a pro at this by now.

Dashboard > Manage Jenkins > Credentials > System > Global Credentials (unrestricted) 
Kind = Secret text
Secret = paste in your token that you received from SonarQube
ID = jenkins-sonarqube-token
Description = ""
Click on Create.

Next, we need to download some of the plugins necessary, move back to the Dashboard.
Dashboard > Manage Jenkins > Plugins > Available Plugins, select the following:
SonarQube Scanner, Sonar Quality Gates, Quality Gates, click the blue install button in the upper right hand corner. There may be a warning pop, however, this is not a production environment, we can ignore it for our purposes.

Return to the dashboard. Go to Manage Jenkins > System enter the following information as shown in the screenshot, same VPC (private IP), different VPC (public IP)

![Screenshot 2024-02-20 130827](https://github.com/dcolanderjr/pipeline_project/assets/131455625/968d1b4b-040a-4dae-87d8-197a81c03157)


Now, we need to create a webhook for SonarQube. Return to the SonarQube console, and navigate to Administration, click the configuration button, and choose webhook.

![sonarqubewebhook](https://github.com/dcolanderjr/pipeline_project/assets/131455625/d2dfd600-ff74-4750-bfa5-6b8b9fce506a)

Next, we need to install docker on the Jenkins server. Move back over to the Jenkins console, from the Dashboard > Manage Jenkins > Plugins - install the following plugins:
Docker, Docker Commons, Docker Pipeline, Docker API, CloudBees Docker Build & Push, docker-build-step
Click install, at the bottom, ensure you click the tick box to restart Jenkins after installation.

Next, we need to create a credential to log in to Docker. Navigate to Dashboard > Manage Jenkins > Credentials, input the following:
![dockerhubcredential](https://github.com/dcolanderjr/pipeline_project/assets/131455625/6461e7d1-0609-4fc9-be35-9b5e67bee6f5)

At this point, you also need to install Trivy. On your Jenkins-Agent, login via SSH, and use the command:
. sudo snap install trivy

Alright now we are at the fun part, KUBERNETES! Your EKS-Bootstrap-Server is up if you used the Terraform, if not, no worries, I'll wait.

Ok, now that it is up, let's get started. First, you will need to perform your updates on your server, so per usual run these commands:
. sudo apt update
. sudo apt upgrade
. sudo apt install unzip
. sudo nano /etc/hostname
Change the name of the server from its IP address, to EKS-Bootstrap-Server
. sudo init 6 (this should reboot your server, wait about 30 seconds and log back in)
. curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
. unzip awscliv2.zip
. sudo ./aws/install
You can now run: /usr/local/bin/aws --version (this should be the response if it is performed correctly)

Next, we now need to install kubectl, use this command to download it:
. sudo su
. curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
. ll 
. chmod +x ./kubectl
Use this command to change the permissions of the ./kubectl directory
. mv kubectl /bin   
All of our executables are in this folder, so need to move it there.
. kubectl version --output=yaml
It will show a connection refused error, this is ok. We have not started the service yet. Nor have we finished the downloads.

. curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
. cd /tmp
. ll
. sudo mv /tmp/eksctl /bin
We need to move this to /bin, because all of our executable files are already there.
. eksctl version

![kubectl](https://github.com/dcolanderjr/pipeline_project/assets/131455625/ef0e3140-5096-49a8-9de8-7e450fb29b68)

Alright, we are going to take a quick detour from the terminal to the console, ensure you are logged into your account that you can create IAM roles with, and delegate permissions. Navigate to IAM, and click on roles, then create role.

Create Role > AWS Service > Use Case (EC2) > Next - (Least privilege is a security best practice, however, we are going to give the EKS role administrator access)

Name the role, eksctl_role. Next, head over to the EC2 console page, click your 'EKS-Bootstrap-Server' and click the actions drop down box > Security > Modify IAM Role > click the drop down and choose the IAM role you just created:

![eksctl_role](https://github.com/dcolanderjr/pipeline_project/assets/131455625/f8baf188-ff53-44fd-9258-213f02a97a0b)

Now we need to create the EKS cluster; head back over to the terminal where your EKS-Bootstrap-Terminal is located, and perform the following per the screenshot (note, use your region, and name your cluster)

insert kubectl config
insert kubectl done

Now, we need to create a namespace for ArgoCD on our cluster, start by issuing this command:
. kubectl create namespace argocd

Next, we need to apply the YAML configuration files to ArgoCD:
. kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Once this is completed, verify you can see the pods created in the ArgoCD namespace:
. kubectl get pods -n argocd

In order to communicate with the API Server, the following commands need to be performed, also the permissions need to be changed.
. curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
. chmod +x /usr/local/bin/argocd

Next, we need to expose the load balancer for the cluster. The process can take about 5 minutes to complete, but run this command:
. kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

In order to get the load balancer URL, we need to run the following command. The second command will allow you to get the password so that we can actually log in to ArgoCD.
. sudo kubectl get svc -n argocd
. sudo kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
. echo RjJxdUZWS0ZVSXZBZEhtVA== | base64 --decode
Copy the response, and stick it in your note pad, you will need it to login to ArgoCD.

![retrievepassword](https://github.com/dcolanderjr/pipeline_project/assets/131455625/8c36b236-8ae2-4c07-84ed-88c97ed4feae)

Run the following command to get the load balancer URL for the ArgoCD Login page:
. kubectl get svc -n argocd

![argocdlogin](https://github.com/dcolanderjr/pipeline_project/assets/131455625/780b9afb-8c01-4b98-9165-8c6f67cb8ca2)

Once you login to ArgoCD, go to User Info, IMMEDIATELY, and change your password to something more friendly. You'll need to paste in the temporary password used to login, and then choose your own.

Next, we need to add our EKS cluster to ArgoCD, and this must be done from the CLI. Issue the following command:

. sudo argocd login XXXXXXXXXXXXXXXXXYOUR CLUSTER NAMEXXXXXXXXXX.us-east-1.elb.amazonaws.com --username admin
type y, and then enter your password that you created in ArgoCD. You should have a green successful message. Return to ArgoCD, go to Settings > scroll down to clusters, and you should see the cluster you just added.

Next run this command to verify from the terminal: You should see your cluster listed. The second command will show your namespace, copy the name, it will start with i-0sdjlkafdsjlkajl-cluster.region.eksctl.io, copy this.
. argocd cluster list
. sudo kubectl config get-contexts
. argocd cluster add i-0sdjlkafdsjlkajl-cluster.region.eksctl.io --name enter_a_name_for_your_cluster
. argocd cluster list 
You should see all of the clusters.

Ok, now we need to connect our repository to our ArgoCD cluster. But, before we do that, clone the second repo to your system, the one named 'gitops-pipeline-app' . This one includes the YAML manifest files that we will need, as well as the CD portion of the pipeline that we will configure in the next few steps. You will need to update the information within these YAML files with your information, as well as the Jenkinsfile as well. Hopefully up to this point you have and iterated the Jenkins file in the 'project-pipeline-app' Jenkins file, and have been following along.

Move back over to the ArgoCD console, when you get there go to:
Settings > Repositories > Connect Repo > Change drop down to HTTPS:
Type = git
project = default
repository URL = "your cloned URL repo"
Username = "your github user name"
Password = "Get hub access token that you created earlier"

In ArgoCD, under applications, click create new app:
Name                = project-pipeline-app
Project Name        = select default
Click the two tick marks on Prune Resources, and Self Heal.
Repository URL      = Choose the repository that you added in the previous step.
Path                = ./
Destination         = Choose your EKS cluster
Namespace           = default

![argocdcreateapp](https://github.com/dcolanderjr/pipeline_project/assets/131455625/c174adcc-5b71-49a9-aff8-14275f1fc30b)

Return to the EKS-Bootstrap-Server, and issue this command:
. sudo kubectl get pods
You should see your pods in a ready state.
. sudo kubectl get svc
You should see your namespace that you created. Copy the external IP field, ie. aksdjfl;asfj-adsafdsf-region.elb.amazonaws.com; copy this into your browser, and append :8080 at the end, and it should bring up the default page of Tomcat. If you put /webapp at the end of the 8080, it should show the web application.

![webapp](https://github.com/dcolanderjr/pipeline_project/assets/131455625/29d41ec9-f4b1-4709-971c-f272b25eff1c)

Return to the Jenkins console, and create a new pipeline. Name it 'gitops-pipeline-app-cd'. Tick the box that states to discard old builds, max builds to keep 2. Click on the button that says 'This project is parameterized' - Add parameter, and choose string parameter. For name, input 'IMAGE_TAG' (the CD job will change the IMAGE_TAG each time our pipeline is triggered, and will update the YML file.)  Click the 'Trigger builds remotely...' button. The authentication token name is 'gitops-token' (we will create this shortly)

For pipeline definition, choose pipeline script from SCM (source control management), choose git, and then enter the repo URL of the 'gitops-pipeline-project' Next, choose your github credentials (should already be in there) for Branch, select main. Click apply, and save.

![cdpipelineimage](https://github.com/dcolanderjr/pipeline_project/assets/131455625/c4f823dc-972b-45fc-9e6b-7b4b2b7a9836)

Return to the pipeline-project repo, and view the Jenkins file in the root directory, click on it, and edit.

"'<YOUR EC2 DNS>.compute-1.amazonaws.com:8080/job/gitops-pipeline-project/buildWithParameters?token=gitops-token'"

I am going to break this line down, so that you can edit this correctly, the first part is the DNS name of your EC2 instance that is the 'Jenkins-Master' edit this with your information. 8080 is the appended port, the gitops-pipeline-project is the name of your CD pipeline in Jenkins.

Now, to complete this, we need to create the JENKINS_API_TOKEN; return to the Jenkins Console, and click on your user name in the upper right hand corner, then choose configuration. Create a new token named 'JENKINS_API_TOKEN' (note: since we are not using HTTPS, you will not be able to use the copy button, highlight and copy, and put in a scratch pad.)

Next, return to the Dashboard, navigate to > Manage Jenkins > Credentials > System > Global Credentials (unrestricted)

Create a new credential. Kind = Secret, ID = JENKINS_API_TOKEN, the secret is the token key you just copied, paste it in. Save. At this point, if you have commented everything, and uncommented everything we have used thus far, this is the last edit we are making on this file in the project-pipeline repository.

![Screenshot 2024-02-20 162453](https://github.com/dcolanderjr/pipeline_project/assets/131455625/e13ef174-2747-474c-b90e-4783949a44e6)

Now, return to the Jenkins console for one final tweak. We need to set the CRON job that will poll the repo to check for changes. Head over to Jenkins, and follow what the instructions of the below screenshot:

![buildtriggerpollscm](https://github.com/dcolanderjr/pipeline_project/assets/131455625/18005431-748c-40af-9d0e-05e65fb18381)

Now, let us test. If we have done everything correctly, it should function as such:
Source Code gets updated > Every minute Jenkins polls repo > Source Code Change = Build Job > Build Job is sent through SonarQube to check for CleanCode > If it passes, it is packaged and sent into a Docker Container > The docker container is scanned by Trivy > The Docker Image is updated in the YAML Manifest > The YAML is deployed in ArgoCD on Kubernetes > Web Application is Updated.

Using the code editor, navigate to the webapp/src/main/webapp directory, and run 'vim index.jsp' change a single letter that is NOT in the code. Replace the header with your name, save and quit.

Once you quit, use 'git add .' , 'git commit -m "test" ' , 'git push origin main', this will push the update of the web application, and start the pipeline. Below are the screenshots capturing the pipeline.

![sourcecodechange](https://github.com/dcolanderjr/pipeline_project/assets/131455625/05202f2b-e3c9-4d26-b5ce-a7963569ace7)

![pipeline-ci](https://github.com/dcolanderjr/pipeline_project/assets/131455625/768fabb1-6ece-42a5-ae7a-e3a65ef02565)

![Screenshot 2024-02-20 164650](https://github.com/dcolanderjr/pipeline_project/assets/131455625/d8983c37-73f7-46ee-a476-0058f8036fe5)

![watiing](https://github.com/dcolanderjr/pipeline_project/assets/131455625/a4e4aa8d-93bc-4b42-a667-b2b9c3fc7d7b)

![cd](https://github.com/dcolanderjr/pipeline_project/assets/131455625/8d4fbe38-48c4-424d-bca2-accdb6e68e0f)

![image](https://github.com/dcolanderjr/pipeline_project/assets/131455625/7fc6fd3f-1b55-4cf8-93c9-512cd188b11c)


And there you have it, that is a simple CI/CD pipeline. Still working out the kinks on GitHub Actions for the next one, but soon!
Thanks again for the read, and a start would be pretty dope too. Take care.

And that completes the CICD project. Hope you enjoyed the ride. Hope you had some fun, learned some new skills.
Until next time, www.kloudkamp.com
