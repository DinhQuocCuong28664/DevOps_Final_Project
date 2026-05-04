pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'dinhquoccuong286/devops-final-app'
        DOCKER_TAG   = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

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

        // ============================================================
        // SECURITY SCANNING (Section 4.2.1 - Mandatory)
        // Uses Trivy to scan the Docker image for critical/high CVEs.
        // Pipeline FAILS if critical or high-severity vulnerabilities found.
        // ============================================================
        stage('Security Scan') {
            steps {
                dir('application') {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
                        nvm use 18

                        # Build image first for scanning
                        docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" .

                        # Scan with Trivy - fail on CRITICAL or HIGH vulnerabilities
                        # Install Trivy if not present
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy..."
                            sudo apt-get install -y wget apt-transport-https gnupg lsb-release
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
                            sudo apt-get update -y
                            sudo apt-get install -y trivy
                        fi

                        echo "Running Trivy security scan on ${DOCKER_IMAGE}:${DOCKER_TAG}..."
                        trivy image --severity CRITICAL,HIGH --exit-code 1 --no-progress "${DOCKER_IMAGE}:${DOCKER_TAG}" || {
                            echo "[FAIL] Security scan found CRITICAL or HIGH vulnerabilities!"
                            echo "Pipeline stopped. Fix vulnerabilities before proceeding."
                            exit 1
                        }
                        echo "[PASS] Security scan passed - no CRITICAL or HIGH vulnerabilities."
                    '''
                }
            }
        }

        // ============================================================
        // DOCKER BUILD & PUSH (Section 4.2.1 - Mandatory)
        // Uses explicit version tag (BUILD_NUMBER + commit SHA), NEVER 'latest'
        // ============================================================
        stage('Docker Build & Push') {
            steps {
                dir('application') {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
                        nvm use 18

                        echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" .

                        echo "Pushing to Docker Hub: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker push "${DOCKER_IMAGE}:${DOCKER_TAG}"

                        echo "Image pushed: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    '''
                }
            }
        }

        // ============================================================
        // DEPLOY TO STAGING (Section 4.2.2 - Multi-environment)
        // Auto-deploys to staging after CI success
        // ============================================================
        stage('Deploy to Staging') {
            steps {
                dir('kubernetes') {
                    sh '''
                        echo "Deploying to STAGING with image tag: ${DOCKER_TAG}"

                        # Replace IMAGE_TAG_PLACEHOLDER with the explicit version tag
                        sed "s|IMAGE_TAG_PLACEHOLDER|${DOCKER_TAG}|g" staging/deployment.yaml | kubectl apply -f -
                        kubectl apply -f staging/service.yaml

                        # Wait for rollout to complete
                        kubectl rollout status deployment/devops-final-deployment -n staging --timeout=120s

                        # Smoke test staging
                        STAGING_POD=$(kubectl get pods -n staging -l app=nodejs-web -o jsonpath='{.items[0].metadata.name}')
                        HTTP_CODE=$(kubectl exec -n staging "$STAGING_POD" -- wget -qO- http://localhost:3000/health 2>/dev/null | grep -c '"status":"ok"' || echo "0")
                        if [ "$HTTP_CODE" -ge 1 ]; then
                            echo "[PASS] Staging smoke test passed!"
                        else
                            echo "[FAIL] Staging smoke test failed!"
                            exit 1
                        fi
                    '''
                }
            }
        }

        // ============================================================
        // MANUAL APPROVAL GATE (Section 4.2.2 - Bonus 7.2)
        // Requires human approval before deploying to production
        // ============================================================
        stage('Approve Production Deployment') {
            input {
                message "Approve deployment to PRODUCTION?"
                ok "Deploy to Production"
                submitterParameter "APPROVER"
                parameters {
                    string(name: 'REASON', defaultValue: '', description: 'Reason for approval')
                }
            }
            steps {
                echo "Approved by: ${APPROVER}"
                echo "Reason: ${REASON}"
            }
        }

        // ============================================================
        // DEPLOY TO PRODUCTION (Section 4.2.2)
        // Rolling update with zero-downtime (maxUnavailable=0)
        // ============================================================
        stage('Deploy to Production') {
            steps {
                dir('kubernetes') {
                    sh '''
                        echo "Deploying to PRODUCTION with image tag: ${DOCKER_TAG}"

                        # Replace IMAGE_TAG_PLACEHOLDER with the explicit version tag
                        sed "s|IMAGE_TAG_PLACEHOLDER|${DOCKER_TAG}|g" deployment.yaml | kubectl apply -f -
                        kubectl apply -f service.yaml
                        kubectl apply -f hpa.yaml

                        # Wait for rollout to complete
                        kubectl rollout status deployment/devops-final-deployment -n production --timeout=120s
                    '''
                }
            }
        }

        // ============================================================
        // SMOKE TEST + AUTOMATED ROLLBACK (Section 7.4 - Bonus)
        // If health check fails after deployment, automatically rollback
        // ============================================================
        stage('Smoke Test & Auto Rollback') {
            steps {
                dir('kubernetes') {
                    sh '''
                        echo "Running production smoke tests..."
                        sleep 10

                        # Check health endpoint via public URL
                        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://www.moteo.fun/health || echo "000")
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "[PASS] Smoke test passed! Health endpoint returned 200"
                        else
                            echo "[FAIL] Smoke test failed! Health endpoint returned $HTTP_CODE"
                            echo "Initiating AUTOMATIC ROLLBACK to previous version..."

                            # Rollback to previous revision
                            kubectl rollout undo deployment/devops-final-deployment -n production
                            kubectl rollout status deployment/devops-final-deployment -n production --timeout=120s

                            echo "[ROLLBACK] Rolled back to previous stable version."
                            exit 1
                        fi

                        # Verify the new image tag is running
                        RUNNING_TAG=$(kubectl get pods -n production -l app=nodejs-web -o jsonpath='{.items[0].spec.containers[0].image}' | cut -d: -f2)
                        echo "Running image tag in production: ${RUNNING_TAG}"
                        if [ "${RUNNING_TAG}" = "${DOCKER_TAG}" ]; then
                            echo "[PASS] Correct version deployed!"
                        else
                            echo "[WARN] Expected ${DOCKER_TAG} but found ${RUNNING_TAG}"
                        fi
                    '''
                }
            }
        }

    }

    post {
        always {
            echo 'Jenkins Pipeline run finished.'
        }
        success {
            echo '[PASS] CI/CD Pipeline completed successfully!'
        }
        failure {
            echo '[FAIL] An error occurred during the pipeline run.'
        }
    }
}
