#!/bin/bash

set -e

# Variables
STANDALONE_PG_PASSWORD="6NfzF8ptUs"  # Change this to your password
NAMESPACE="default"

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

    helm install standalone-postgresqldb -f standalone-values.yaml bitnami/postgresql
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

