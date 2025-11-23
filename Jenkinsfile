pipeline {
  agent any
  environment {
    REGISTRY = "localhost:5000"
    IMAGE_NAME = "${REGISTRY}/devopslearning"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build image') {
      steps {
        script {
          // tag with build number for easy rollback
          def imgTag = "${env.BUILD_NUMBER}"
          env.IMAGE_TAG = imgTag
          // build using host docker (docker binary available in container via mount or TCP)
          sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
        }
      }
    }

    stage('Login to local registry (if required)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'registry-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            if [ -n "$REG_USER" ]; then
              echo "$REG_PASS" | docker login ${REGISTRY} -u "$REG_USER" --password-stdin
            else
              echo "No registry credentials provided, attempting anonymous push"
            fi
          '''
        }
      }
    }

    stage('Push image') {
      steps {
        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
        sh "docker push ${IMAGE_NAME}:latest"   // keep latest pointer
      }
    }

    stage('Deploy') {
      steps {
        // pull and start with the new image; override TAG env so compose pulls the right tag
        sh "docker compose -f docker-compose.app.yml pull || true"
        sh "TAG=${IMAGE_TAG} docker compose -f docker-compose.app.yml up -d"
      }
    }

    stage('Wait & Healthcheck') {
      steps {
        script {
          // wait for container to report healthy (max ~90s)
          def status = sh script: '''
            for i in {1..18}; do
              HEALTH=$(docker inspect --format='{{json .State.Health.Status}}' devopslearning-api 2>/dev/null || echo "null")
              if [ "$HEALTH" = "\"healthy\"" ]; then
                echo "healthy"
                exit 0
              fi
              sleep 5
            done
            echo "unhealthy"
            exit 1
          ''', returnStatus: true

          if (status != 0) {
            error "Healthcheck failed after deploy"
          }
        }
      }
    }
  }

  post {
    failure {
      // on failure, attempt a simple rollback to previous tag (BUILD_NUMBER-1), if exists
      script {
        def prev = env.BUILD_NUMBER.toInteger() - 1
        if (prev > 0) {
          echo "Attempting rollback to tag ${prev}"
          sh "docker pull ${IMAGE_NAME}:${prev} || true"
          sh "TAG=${prev} docker compose -f docker-compose.app.yml up -d"
        } else {
          echo "No previous build, manual intervention required"
        }
      }
    }
  }
}
