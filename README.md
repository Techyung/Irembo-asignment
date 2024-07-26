# Irembo-asignment
Deploying  Kubernetes using minikube in a local environment 


let's break down the tasks step by step to achieve this. We'll start with setting up the Minikube cluster, then deploy the PostgreSQL database using Helm, set up services and load balancers, create and populate a demo database, and finally set up asynchronous replication.

### Step 1: Set Up Minikube Cluster
## 1. Install Minikube: 

## minikube installation.
## requirements.
##  2 CPUs or more
##  2GB of free memory
##  20GB of free disk space

New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing

## Add the minikube.exe binary to your PATH.

$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
}


##  Start Minikube with the specified resources and docker driver:
  
    minikube start --cpus 2 --memory 2048 --disk-size 20g --driver=docker



## Install and Set Up kubectl 

curl.exe -LO "https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl.exe"

## Download the kubectl checksum file:

curl.exe -LO "https://dl.k8s.io/v1.30.0/bin/windows/amd64/kubectl.exe.sha256"

## Validate the kubectl binary against the checksum file:

CertUtil -hashfile kubectl.exe SHA256
type kubectl.exe.sha256

## Using PowerShell to automate the verification using the -eq operator to get a True or False result:

 $(Get-FileHash -Algorithm SHA256 .\kubectl.exe).Hash -eq $(Get-Content .\kubectl.exe.sha256)

## Test to ensure the version of kubectl is the same as downloaded:

kubectl version --client
kubectl version --client --output=yaml

## Install on Windows using Chocolatey, Scoop, or winget
## choco

choco install kubernetes-cli

## scoop
scoop install kubectl

## winget
winget install -e --id Kubernetes.kubectl

## Test to ensure the version you installed is up-to-date:

kubectl version --client

## Navigate to your home directory:
# If you're using cmd.exe, run: cd %USERPROFILE%

cd ~

## Create the .kube directory:

mkdir .kube

## Change to the .kube directory you just created:

cd .kube

## Configure kubectl to use a remote Kubernetes cluster:

New-Item config -type file

## In order for kubectl to find and access a Kubernetes cluster, it needs a kubeconfig file, which is created automatically when you create a cluster using kube-up.sh or successfully deploy a Minikube cluster. By default, kubectl configuration is located at 

~/.kube/config

## Check that kubectl is properly configured by getting the cluster state:

kubectl cluster-info

## If you see a message similar to the following, kubectl is not configured correctly or is not able to connect to a Kubernetes cluster.
## If kubectl cluster-info returns the url response but you can't access your cluster, to check whether it is configured properly, use:

kubectl cluster-info dump


## The kubectl completion script for PowerShell can be generated with the command 

kubectl completion powershell

## To do so in all your shell sessions, add the following line to your $PROFILE file:

kubectl completion powershell | Out-String | Invoke-Expression

## To add the generated script to your $PROFILE file, run the following line in your powershell prompt:

kubectl completion powershell >> $PROFILE

## Install kubectl convert plugin

curl.exe -LO "https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl-convert.exe"

## Download the kubectl-convert checksum file:

curl.exe -LO "https://dl.k8s.io/v1.30.0/bin/windows/amd64/kubectl-convert.exe.sha256"

## Validate the kubectl-convert binary against the checksum file:
## Using Command Prompt to manually compare CertUtil's output to the checksum file downloaded:

CertUtil -hashfile kubectl-convert.exe SHA256
type kubectl-convert.exe.sha256

## Using PowerShell to automate the verification using the -eq operator to get a True or False result:

$($(CertUtil -hashfile .\kubectl-convert.exe SHA256)[1] -replace " ", "") -eq $(type .\kubectl-convert.exe.sha256)

## Append or prepend the kubectl-convert binary folder to your PATH environment variable.
## Verify the plugin is successfully installed.

kubectl convert --help

### Step 2: Deploy PostgreSQL Database using Helm

## 1. Install Helm : Download and install Helm from the [official website]
(https://helm.sh/docs/intro/install/).

## 2. Add the Bitnami repository

 (contains the PostgreSQL Helm charts):

    helm repo add bitnami https://charts.bitnami.com/bitnami

## 3. Create the custom 'values.yaml' file  for PostgreSQL deployment:
    
    postgresql:
      primary:
        service:
          type: Loadbalancer
        persistence:
          enabled: true
          size: 1Gi
          mountPath: /bitnami/postgresql
      replicaCount: 1
      replication:
        enabled: true
   
## 4. Deploy PostgreSQL using Helm:
    
    helm install my-postgresql -f values.yaml bitnami/postgresql



## PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    my-postgresql.default.svc.cluster.local - Read/Write connection

## To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

## To connect to your database run the following command:

    kubectl run my-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:16.3.0-debian-12-r23 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host my-postgresql -U postgres -d postgres -p 5432

## To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/my-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
    
### Step 3: Create a Service to Connect to Stateful Database Instance

## Extract the external IP and NodePort**:
  
    kubectl get svc my-postgresql -o jsonpath='{.spec.ports[0].nodePort}'
    kubectl get nodes -o wide
    
##Create a Kubernetes Service YAML
    
    apiVersion: v1
    kind: Service
    metadata:
      name: postgresql-lb
    spec:
      type: LoadBalancer
      ports:
        - port: 5432
          nodePort: 32000
      selector:
        app.kubernetes.io/name: postgresql
   
## Apply the Service YAML
   
    kubectl apply -f postgresql-lb.yaml
   
kubectl expose deployment postgresql --type=LoadBalancer --port=32000


### Step 4: Develop a Python Script to Create a Demo Database
## 1.Install PostgreSQL and Faker libraries:

    pip install psycopg2-binary faker
    
## 2. Python Script
    
    import psycopg2
    from faker import Faker

    def create_database_and_tables():
        conn = psycopg2.connect(
            dbname="postgres",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
        cursor.execute("CREATE DATABASE demo_db;")
        conn.close()
        
        conn = psycopg2.connect(
            dbname="demo_db",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        cursor = conn.cursor()
        
        cursor.execute("""
            CREATE TABLE parent (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100)
            );
        """)
        
        cursor.execute("""
            CREATE TABLE child (
                id SERIAL PRIMARY KEY,
                parent_id INTEGER REFERENCES parent(id),
                description VARCHAR(100)
            );
        """)
        conn.commit()
        conn.close()

    def insert_fake_data():
        conn = psycopg2.connect(
            dbname="demo_db",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        cursor = conn.cursor()
        
        fake = Faker()
        for _ in range(100000):
            cursor.execute("INSERT INTO parent (name) VALUES (%s) RETURNING id;", (fake.name(),))
            parent_id = cursor.fetchone()[0]
            cursor.execute("INSERT INTO child (parent_id, description) VALUES (%s, %s);", (parent_id, fake.text(max_nb_chars=100)))
        
        conn.commit()
        conn.close()

    if __name__ == "__main__":
        create_database_and_tables()
        insert_fake_data()
    
### Step 5: Deploy a Standalone PostgreSQL Database and Set Up Async Replication
## 1. Create a separate 'values-standalone.yaml' for standalone PostgreSQL:
   
    postgresql:
      primary:
        persistence:
          enabled: true
          size: 1Gi
          mountPath: /bitnami/postgresql
    
2. Deploy standalone PostgreSQL:
 
    helm install standalone-postgresql -f values-standalone.yaml bitnami/postgresql

## To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default standalone-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

## To connect to your database run the following command:

    kubectl run standalone-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:16.3.0-debian-12-r23 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host standalone-postgresql -U postgres -d postgres -p 5432

## To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/standalone-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432

   
## 3.Set up asynchronous replication:
To set up a standalone PostgreSQL database using Helm and configure asynchronous replication from your Kubernetes cluster’s PostgreSQL instance to this standalone database, follow these steps:

### Create Values File for Standalone PostgreSQL
## Create a file named `standalone-values.yaml` with the following content:

postgresql:
  primary:
    persistence:
      enabled: true
      size: 1Gi
      mountPath: /bitnami/postgresql

### Step 4: Deploy Standalone PostgreSQL using Helm
Install the standalone PostgreSQL database with the configuration specified in 'standalone-values.yaml':

helm install standalone-postgresql -f standalone-values.yaml bitnami/postgresql


###  Retrieve Standalone PostgreSQL Connection Details

Get the connection details of the standalone PostgreSQL database:

STANDALONE_PG_HOST=$(kubectl get svc standalone-postgresql -o jsonpath='{.spec.clusterIP}')
STANDALONE_PG_PORT=$(kubectl get svc standalone-postgresql -o jsonpath='{.spec.ports[0].port}')
STANDALONE_PG_USER="postgres"
STANDALONE_PG_PASSWORD="yourpassword"  # Change this to your password

###  Update Values File for Kubernetes PostgreSQL with Replication
## Create or update the `values-replication.yaml` file to include replication configuration:

postgresql:
  primary:
    replication:
      enabled: true
      asyncReplica:
        hostname: ${STANDALONE_PG_HOST}
        port: ${STANDALONE_PG_PORT}
        user: ${STANDALONE_PG_USER}
        password: ${STANDALONE_PG_PASSWORD}


### Upgrade PostgreSQL Cluster with Replication
## Upgrade the PostgreSQL deployment in your cluster with the replication settings:

helm upgrade my-postgresql -f values-replication.yaml bitnami/postgresql

###  Verify Replication Status
## Check the status of the PostgreSQL pods and replication:

kubectl get pods -l app.kubernetes.io/name=postgresql
kubectl exec -it <postgresql-pod-name> -- psql -U postgres -d postgres -c "SELECT * FROM pg_stat_replication;"

### Complete Script

Here’s a complete script (`setup-standalone-replication.sh`) that combines all the steps:

#!/bin/bash

set -e

# Variables
STANDALONE_PG_PASSWORD="yourpassword"  # Change this to your password
NAMESPACE="default"

# Function to install Helm
install_helm() {
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
}

# Function to deploy standalone PostgreSQL
deploy_standalone_postgresql() {
    echo "Deploying standalone PostgreSQL..."
    cat <<EOF > standalone-values.yaml
postgresql:
  primary:
    persistence:
      enabled: true
      size: 1Gi
      mountPath: /bitnami/postgresql
EOF

    helm install standalone-postgresql -f standalone-values.yaml bitnami/postgresql
}

# Function to get standalone PostgreSQL connection details
get_standalone_details() {
    echo "Retrieving standalone PostgreSQL connection details..."
    STANDALONE_PG_HOST=$(kubectl get svc standalone-postgresql -o jsonpath='{.spec.clusterIP}')
    STANDALONE_PG_PORT=$(kubectl get svc standalone-postgresql -o jsonpath='{.spec.ports[0].port}')
    STANDALONE_PG_USER="postgres"
    STANDALONE_PG_PASSWORD="${STANDALONE_PG_PASSWORD}"
    echo "Standalone PostgreSQL - Host: ${STANDALONE_PG_HOST}, Port: ${STANDALONE_PG_PORT}, User: ${STANDALONE_PG_USER}, Password: ${STANDALONE_PG_PASSWORD}"
}

# Function to configure replication for Kubernetes PostgreSQL
configure_replication() {
    echo "Configuring replication for Kubernetes PostgreSQL..."
    cat <<EOF > values-replication.yaml
postgresql:
  primary:
    replication:
      enabled: true
      asyncReplica:
        hostname: ${STANDALONE_PG_HOST}
        port: ${STANDALONE_PG_PORT}
        user: ${STANDALONE_PG_USER}
        password: ${STANDALONE_PG_PASSWORD}
EOF

    helm upgrade my-postgresql -f values-replication.yaml bitnami/postgresql
}

# Function to verify replication status
verify_replication() {
    echo "Verifying replication status..."
    kubectl get pods -l app.kubernetes.io/name=postgresql
    kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d postgres -c "SELECT * FROM pg_stat_replication;"
}

# Main function to execute all steps
main() {
    deploy_standalone_postgresql
    get_standalone_details
    configure_replication
    verify_replication
    echo "Setup complete! Replication is configured."
}

# Run the script
main

### Running the Script

1. **Make the script executable**:
  
    chmod +x setup-standalone-replication.sh
  

2. **Run the script**:
    ./setup-standalone-replication.sh
   
This script will automate the deployment of the standalone PostgreSQL database, set up replication from the Kubernetes PostgreSQL cluster, and verify the replication status. Ensure you replace `yourpassword` with your actual password.



