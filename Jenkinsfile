pipeline {
  agent { label 'terraform' }

  stages{
    stage('Code Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Analysis') {
      environment {
        scannerHome = tool 'SonarQubeScanner'
      }
      steps {
        withSonarQubeEnv('SonarQube') {
          sh "${scannerHome}/bin/sonar-scanner"
        }
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Terraform Init'){
      steps{
        sh 'terraform init'
      }
    }

    stage('Terraform Apply'){
      steps{
        withCredentials([[
          $class: 'AWSCredentials',
          credentialsId: "prodAccountXYZ",
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
        sh 'terraform apply --auto-approve'
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}