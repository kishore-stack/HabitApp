# Habit Tracker — Production-Style DevOps CI/CD

A Spring Boot Habit Tracker application deployed through a production-style CI/CD and GitOps workflow using Jenkins, Maven, SonarQube, Docker, Helm, Kubernetes, and Argo CD.

## Project Overview

This project demonstrates an end-to-end DevOps workflow:

```text
Developer
   |
   v
GitHub - HabitApp
   |
   v
Jenkins CI
   |
   +--> Maven Build
   +--> Unit Tests
   +--> SonarQube Analysis
   +--> Quality Gate
   +--> Docker Build
   +--> Docker Push
   |
   v
GitOps Repository - HabitApp-GitOps
   |
   v
Argo CD
   |
   v
Kubernetes / Minikube
   |
   +--> Habit Tracker Pod
   +--> Habit Tracker Pod
   +--> Habit Tracker Pod
   |
   v
Kubernetes Service
   |
   v
Habit Tracker Application
```

## Application

The application is a self-contained Spring Boot REST API and dashboard for tracking daily/weekly habits and streaks.

- Java 21
- Spring Boot 3.3.4
- Maven
- Vanilla HTML/CSS/JavaScript dashboard
- In-memory data storage using `ConcurrentHashMap`
- Spring Boot Actuator for health endpoints

Because application data is stored in memory, restarting the application clears the data.

## DevOps Technology Stack

| Area | Technology |
|---|---|
| Source Control | Git, GitHub |
| Application | Java 21, Spring Boot 3.3.4 |
| Build | Maven 3.9.16 |
| CI | Jenkins |
| Code Quality | SonarQube |
| Testing | Maven / Spring Boot tests |
| Coverage | JaCoCo |
| Containerization | Docker |
| Container Registry | Docker Hub |
| Packaging | Helm |
| Orchestration | Kubernetes |
| Local Kubernetes | Minikube |
| GitOps CD | Argo CD |
| Monitoring | Kubernetes Metrics Server |
| Deployment Strategy | RollingUpdate |

## Repositories

### Application Repository

```text
https://github.com/kishore-stack/HabitApp.git
```

Contains:

```text
HabitApp/
├── src/
├── pom.xml
├── Dockerfile
├── .dockerignore
├── Jenkinsfile
└── README.md
```

### GitOps Repository

```text
https://github.com/kishore-stack/HabitApp-GitOps.git
```

Contains the Helm deployment configuration used by Argo CD:

```text
HabitApp-GitOps/
└── helm/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── _helpers.tpl
```

Deployment configuration is separated from the application source repository.

---

# CI/CD Pipeline

The Jenkins pipeline performs the following stages:

```text
Checkout
   |
Maven Build
   |
Unit Test
   |
SonarQube Analysis
   |
Quality Gate
   |
Docker Build
   |
Docker Push
   |
Update GitOps Repository
   |
Git Push
```

Jenkins does not directly deploy the application to Kubernetes.

Argo CD is responsible for the CD/GitOps deployment.

## Jenkins Pipeline Stages

### 1. Checkout

Jenkins checks out the application source code from GitHub.

### 2. Maven Build

```bash
mvn -B clean package -DskipTests
```

The application is packaged into an executable JAR.

### 3. Unit Test

```bash
mvn -B test
```

The project test suite is executed before the container image is created.

### 4. SonarQube Analysis

Jenkins runs SonarQube analysis using the SonarQube credential stored in Jenkins Credentials.

The pipeline uses:

```text
SONAR_TOKEN
```

as a Jenkins-managed secret rather than storing the actual token in source code.

### 5. Quality Gate

Jenkins waits for the SonarQube Quality Gate result.

The pipeline is configured to stop if the Quality Gate fails.

### 6. Docker Build

The Docker image is built from the application Dockerfile.

The image tag is generated from the Git commit SHA:

```text
srkishore/habit-tracker:<git-sha>
```

Example image used during the completed deployment:

```text
srkishore/habit-tracker:95378294e7f5
```

### 7. Docker Push

Jenkins authenticates to Docker Hub using a Jenkins credential and pushes the image.

The Docker Hub repository is:

```text
srkishore/habit-tracker
```

### 8. GitOps Update

After pushing the Docker image, Jenkins clones the GitOps repository and updates:

```text
helm/values.yaml
```

with the new image tag.

Jenkins then commits and pushes the change to GitHub.

Example:

```text
Update Habit Tracker image to 95378294e7f5
```

---

# GitOps with Argo CD

Argo CD watches the GitOps repository.

The deployment flow is:

```text
Jenkins
   |
   | update image tag
   v
HabitApp-GitOps
   |
   | Git commit
   v
Argo CD
   |
   | detects Git change
   v
OutOfSync
   |
   | Synchronize
   v
Kubernetes
```

For the completed deployment, Argo CD detected the GitOps change and synchronized the application.

Final Argo CD status:

```text
Sync Status: Synced
Health Status: Healthy
```

---

# Kubernetes Deployment

The application is deployed to Kubernetes using Helm.

The completed deployment used:

```text
Replicas: 3
```

All three Pods were verified as running.

Example:

```text
habit-tracker-677b49999b-2vccc
habit-tracker-677b49999b-dns5p
habit-tracker-677b49999b-pnwb9
```

All three Pods were running:

```text
1/1 Running
```

## Docker Image

The verified image running in all three Pods was:

```text
srkishore/habit-tracker:95378294e7f5
```

This verified the complete:

```text
Jenkins
   |
Docker Build
   |
Docker Hub
   |
GitOps update
   |
Argo CD
   |
Kubernetes
   |
95378294e7f5
```

workflow.

## Kubernetes Service

The application is exposed using a NodePort Service.

Example:

```text
Service Port: 8080
NodePort:     32275
```

The application was successfully accessed through the Minikube service URL.

---

# Helm

Helm is used to package the Kubernetes deployment configuration.

The Helm chart contains:

```text
Chart.yaml
values.yaml
templates/
├── deployment.yaml
├── service.yaml
└── _helpers.tpl
```

The image repository and tag are configured through `values.yaml`.

Example:

```yaml
image:
  repository: srkishore/habit-tracker
  tag: "95378294e7f5"
  pullPolicy: Always
```

Helm operations demonstrated during the project included:

```bash
helm lint
helm install
helm upgrade
helm rollback
```

---

# Kubernetes Health Probes

Spring Boot Actuator provides health endpoints:

```text
/actuator/health
/actuator/health/liveness
/actuator/health/readiness
```

Kubernetes uses:

### Readiness Probe

```text
/actuator/health/readiness
```

The readiness probe determines whether the Pod is ready to receive traffic.

### Liveness Probe

```text
/actuator/health/liveness
```

The liveness probe helps Kubernetes determine whether the application is still running correctly.

---

# Resource Management

The application Pods use Kubernetes resource requests and limits.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

This provides Kubernetes with resource requirements and prevents the container from using unlimited CPU or memory.

---

# Rolling Updates

The deployment uses the Kubernetes `RollingUpdate` strategy.

Configuration:

```yaml
rollingUpdate:
  maxUnavailable: 0
  maxSurge: 1
```

This was tested during the project by changing the application image version and deploying the updated image.

The final deployment also demonstrated a rolling transition to the newer image.

---

# Monitoring

Kubernetes Metrics Server was enabled in Minikube.

Metrics can be viewed with:

```bash
kubectl top pods
kubectl top nodes
```

Example verified application metrics:

```text
Habit Tracker Pods

CPU:     5m - 7m
Memory:  137Mi - 153Mi
```

The Minikube node was also checked with:

```bash
kubectl top nodes
```

---

# Logging

Application logs can be viewed using:

```bash
kubectl logs deployment/habit-tracker --tail=50
```

The verified application logs showed:

```text
Spring Boot 3.3.4
Java 21.0.12.1
Tomcat started on port 8080
Started HabitTrackerApplication
```

---

# Security

The project follows these security practices:

- SonarQube token stored in Jenkins Credentials
- Docker Hub credentials stored in Jenkins Credentials
- GitHub/GitOps credentials stored in Jenkins Credentials
- Secrets are passed to Jenkins through credential bindings
- Actual credentials are not stored in the Jenkinsfile
- Docker runtime container uses a non-root user
- Kubernetes resource limits are configured
- Health probes are configured
- Deployment configuration is separated into a GitOps repository

The application repository was checked for common secret keywords. Only credential variable names/placeholders were found; no actual credential values were committed.

## Docker Non-Root User

The Docker runtime image creates and uses:

```text
appuser
UID 1001
```

The Spring Boot application was verified running as:

```text
appuser
```

rather than root.

---

# Local Development

## Requirements

- JDK 21+
- Maven 3.9.16
- Docker
- Kubernetes / Minikube
- Helm
- kubectl
- Jenkins
- SonarQube
- Argo CD

## Build

```bash
mvn clean package
```

## Run Locally

```bash
java -jar target/habit-tracker.jar
```

Open:

```text
http://localhost:8080
```

## Run Tests

```bash
mvn test
```

---

# Useful Kubernetes Commands

Check Pods:

```bash
kubectl get pods
```

Check Deployment:

```bash
kubectl get deployment habit-tracker
```

Check Service:

```bash
kubectl get svc habit-tracker
```

Check logs:

```bash
kubectl logs deployment/habit-tracker
```

Check resource usage:

```bash
kubectl top pods
kubectl top nodes
```

Check the deployed image:

```bash
kubectl get deployment habit-tracker -o wide
```

Get the Minikube application URL:

```bash
minikube service habit-tracker --url
```

---

# Verification Checklist

The following components were completed and verified during the project:

- [x] Java Spring Boot application
- [x] Maven build
- [x] Unit tests
- [x] SonarQube analysis
- [x] SonarQube Quality Gate
- [x] Docker multi-stage build
- [x] Docker Hub image push
- [x] Jenkins CI pipeline
- [x] GitOps repository
- [x] Helm chart
- [x] Kubernetes deployment
- [x] Kubernetes Service
- [x] 3 application replicas
- [x] RollingUpdate strategy
- [x] Liveness probe
- [x] Readiness probe
- [x] Resource requests and limits
- [x] Argo CD installation
- [x] Argo CD synchronization
- [x] Jenkins image update to GitOps repository
- [x] Application verification through Kubernetes
- [x] Kubernetes logging
- [x] Kubernetes Metrics Server
- [x] CPU and memory monitoring
- [x] Jenkins credential-based secret handling
- [x] Non-root Docker runtime

---

# Final Architecture

```text
                         GitHub
                    HabitApp Repository
                           |
                           v
                       Jenkins
                           |
              +------------+-------------+
              |            |             |
          Maven Build   Unit Tests   SonarQube
              |                          |
              |                     Quality Gate
              |                          |
              +------------+-------------+
                           |
                           v
                      Docker Build
                           |
                           v
                       Docker Hub
                           |
                           v
                HabitApp-GitOps Repository
                           |
                           v
                        Argo CD
                           |
                           v
                    Kubernetes / Minikube
                           |
              +------------+-------------+
              |            |             |
            Pod 1        Pod 2         Pod 3
              |            |             |
              +------------+-------------+
                           |
                           v
                    Habit Tracker App
                           |
                           v
                  NodePort Service :32275
```

## Project Outcome

This project demonstrates a complete CI-to-GitOps deployment workflow in which a code change can be built, tested, analyzed, containerized, pushed to a registry, represented as a GitOps change, synchronized by Argo CD, and deployed to Kubernetes.
