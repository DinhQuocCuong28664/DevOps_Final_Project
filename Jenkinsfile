pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            // Chạy dưới quyền root trong container để tránh lỗi phân quyền (nếu có)
            args '-u root:root'
        }
    }

    stages {
        stage('Lấy mã nguồn') {
            steps {
                checkout scm
            }
        }

        stage('Cài đặt Dependencies') {
            steps {
                dir('application') {
                    sh 'npm ci'
                }
            }
        }

        stage('Kiểm tra chất lượng code (Lint)') {
            steps {
                dir('application') {
                    sh 'npm run lint'
                }
            }
        }

        stage('Hoàn tất') {
            steps {
                echo 'CI Pipeline chạy trên Jenkins thành công!'
            }
        }
    }
    
    post {
        always {
            echo 'Đã kết thúc quá trình chạy Jenkins Pipeline.'
        }
        success {
            echo '🎉 PASS: Mã nguồn đạt tiêu chuẩn.'
        }
        failure {
            echo '❌ FAIL: Có lỗi xảy ra trong quá trình kiểm tra.'
        }
    }
}
