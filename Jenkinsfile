pipeline {
    agent any // Không dùng Docker nữa

    stages {
        stage('Lấy mã nguồn') {
            steps {
                checkout scm
            }
        }

        stage('Cài đặt Node.js và Dependencies') {
            steps {
                dir('application') {
                    // Dùng NVM tải Node 18 thẳng vào phiên làm việc Jenkins luôn
                    sh '''
                        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
                        nvm install 18
                        nvm use 18
                        npm ci
                    '''
                }
            }
        }

        stage('Kiểm tra chất lượng code (Lint)') {
            steps {
                dir('application') {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
                        nvm use 18
                        npm run lint
                    '''
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
