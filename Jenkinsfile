pipeline {
    agent any

    environment {
        API_IMAGE = 'products-backend'
        API_TAG   = "${env.BUILD_NUMBER}"
        DB_CONT   = 'mssql'
        DB_PASS   = 'Your_password123'
        DB_VOL    = 'mssql-data'
        PORT      = '8080'
        NETWORK   = 'products-net'
    }

    stages {

        /* ---------- 1. Код ---------- */
        stage('Checkout') {
            steps { checkout scm }
        }

        /* ---------- 2. Мережа ---------- */
        stage('Ensure Docker network') {
            steps {
                sh "docker network inspect ${NETWORK} >/dev/null 2>&1 || docker network create ${NETWORK}"
            }
        }

        /* ---------- 3. Збірка образу бекенду ---------- */
        stage('Build backend image') {
            steps {
                sh """
                    docker build -t ${API_IMAGE}:${API_TAG} -t ${API_IMAGE}:latest .
                """
            }
        }

        /* ---------- 4. Запуск / оновлення MSSQL ---------- */
        stage('Ensure database container') {
            steps {
                sh """
                    docker rm -f ${DB_CONT} || true
                    docker volume create ${DB_VOL} || true

                    docker run -d --name ${DB_CONT} \\
                      --network ${NETWORK} \\
                      -e ACCEPT_EULA=Y \\
                      -e SA_PASSWORD=${DB_PASS} \\
                      -p 1433:1433 \\
                      -v ${DB_VOL}:/var/opt/mssql \\
                      --restart unless-stopped \\
                      mcr.microsoft.com/mssql/server:2022-latest
                """
            }
        }

        /* ---------- 5. Чекаємо готовності MSSQL ---------- */
        stage('Wait MSSQL ready') {
            steps {
                sh """
                    echo '⏳ waiting SQL Server…'
                    for i in {1..40}; do
                docker exec ${DB_CONT} /opt/mssql-tools/bin/sqlcmd \\
                   -S localhost -U sa -P ${DB_PASS} -Q "SELECT 1" && {
                   echo '✅ SQL ready'; exit 0; }
                sleep 2
            done
            echo '⛔ SQL did not start in time'; exit 1
                """
            }
        }

        /* ---------- 6. Деплой бекенду ---------- */
        stage('Deploy backend container') {
            steps {
                sh """
                    docker rm -f ${API_IMAGE} || true

                    docker run -d --name ${API_IMAGE} \\
                      --network ${NETWORK} \\
                      --restart unless-stopped \\
                      -p ${PORT}:80 \\
                      -e ASPNETCORE_ENVIRONMENT=Development \\
                      -e ConnectionStrings__Default="Server=${DB_CONT};Database=Products;User=sa;Password=${DB_PASS};Encrypt=False;" \\
                      ${API_IMAGE}:latest
                """
            }
        }

        /* ---------- 7. Health-check ---------- */
        stage('Health check') {
            steps {
                retry(10) {
                    sleep 3
                    sh "curl -sf http://localhost:${PORT}/swagger/index.html > /dev/null"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Backend #${BUILD_NUMBER} запущено на порті :${PORT}"
        }
        failure {
            echo "❌ Deploy або health-check не пройшов"
        }
    }
}
