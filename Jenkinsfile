pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Node.js and Dependencies') {
            steps {
                dir('application') {
                    // Use NVM to load Node 18 directly into the Jenkins session
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

        stage('Lint') {
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

        stage('Done') {
            steps {
                echo 'CI Pipeline completed successfully on Jenkins!'
            }
        }
    }

    post {
        always {
            echo 'Jenkins Pipeline run finished.'
        }
        success {
            echo '[PASS] Code quality check passed.'
        }
        failure {
            echo '[FAIL] An error occurred during the pipeline run.'
        }
    }
}
