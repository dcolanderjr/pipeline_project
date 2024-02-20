// Second pipeline written in groovy for terraform deployment.
// This pipeline will be used to deploy the infrastructure using terraform.
// Any changes to the infrastructure will be made in the terraform code and then pushed to the 
// repository. Then the pipeline will be triggered to deploy the infrastructure.

pipeline {
    agent { label 'Jenkins-Agent' }
}

    stages {
        stage('Preparing') {
            steps {
                sh "echo Preparing"
            }
        }
        
        stage('Pulling Updated Git Source Code, please wait.') {
            steps {
                git branch: '*/main', credentialsId: 'github', url: 'https://github.com/dcolanderjr/pipeline_project'
                sh "echo Code has been pulled from the repository."
            }
        }

        stage('Terraform init') {
            steps {
                sh 'echo Performing Terraform initialization'
                withAWS(credentials: 'Jenkins-Server', region: 'us-east-1') {
                sh 'terraform init'
                sh 'echo Terraform has been initialized.'
                }
            }
        }

        stage('Terraform plan') {
            steps {
                sh 'echo Performing Terraform plan'
                withAWS(credentials: 'Jenkins-Server', region: 'us-east-1') {
                sh 'terraform plan'
                sh 'echo Terraform plan has been completed.'
                }
            }
        }

        stage('Terraform apply --auto-approve') {
            steps {
                sh 'echo Deploying the infrastructure using Terraform'
                withAWS(credentials: 'Jenkins-Server', region: 'us-east-1') {
                sh 'terraform apply --auto-approve'
                sh 'echo Terraform apply has been completed.'
                }
            }
        }
}

