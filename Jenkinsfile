pipeline {
    agent any

    environment {
        API_IMAGE = 'products-backend'
        API_TAG   = "${env.BUILD_NUMBER}"
        DB_CONT   = 'mssql'
        DB_PASS   = 'Your_password123'
        DB_VOL    = 'mssql-data'
        PORT      = '8080'
    }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build backend image') {
            steps {
                sh """
                  docker build -t ${API_IMAGE}:${API_TAG} -t ${API_IMAGE}:latest .
                """
            }
        }

        stage('Ensure database container') {
            steps {
                script {
                    def exists = sh(
                            script: "docker ps -a --format '{{.Names}}' | grep -w ${DB_CONT} || true",
                            returnStatus: true)
                    if (exists != 0) {
                        sh """
                          docker volume create ${DB_VOL} || true
                          docker run -d --name ${DB_CONT} \
                              -e 'ACCEPT_EULA=Y' \
                              -e 'SA_PASSWORD=${DB_PASS}' \
                              -p 1433:1433 \
                              -v ${DB_VOL}:/var/opt/mssql \
                              --restart unless-stopped \
                              mcr.microsoft.com/mssql/server:2022-latest
                        """
                    } else {
                        echo "SQL Server вже працює – пропускаю старт"
                    }
                }
            }
        }

        stage('Deploy backend container') {
            steps {
                sh """
                  # якщо старий контейнер існує – зупинити й видалити
                  docker rm -f ${API_IMAGE} || true

                  docker run -d --name ${API_IMAGE} \
                    --restart unless-stopped \
                    -p ${PORT}:80 \
                    --link ${DB_CONT}:mssql \\
                    -e ASPNETCORE_ENVIRONMENT=Development \\
                    -e ConnectionStrings__Default='Server=mssql;Database=Products;User=sa;Password=${DB_PASS};Encrypt=False;' \\
                    ${API_IMAGE}:latest
                """
            }
        }

        stage('Health check') {
            steps {
                script {
                    retry(10) {
                        sleep 3
                        sh "curl -sf http://localhost:${PORT}/swagger/index.html > /dev/null"
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ Backend #${BUILD_NUMBER} запущено на :${PORT}" }
        failure { echo "❌ Deploy/health-check не пройшов" }
    }
}

