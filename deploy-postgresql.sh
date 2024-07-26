#!/bin/bash

set -e

# Variables
POSTGRESQL_PASSWORD="test1234"  # Change this password
NAMESPACE="postgres"

# Create PostgreSQL Deployment
cat <<EOF > postgresql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
        - name: postgresql
          image: postgres:13
          env:
            - name: POSTGRES_DB
              value: "demo_db"
            - name: POSTGRES_USER
              value: "postgres"
            - name: POSTGRES_PASSWORD
              value: "${POSTGRESQL_PASSWORD}"
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-data
          persistentVolumeClaim:
            claimName: postgres-pvc
EOF

# Create Persistent Volume Claim
cat <<EOF > postgres-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Create Service to Expose PostgreSQL
cat <<EOF > postgresql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgresql-service
spec:
  type: LoadBalancer
  ports:
    - port: 5432
      targetPort: 5432
  selector:
    app: postgresql
EOF

# Apply Kubernetes Resources
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgresql-service.yaml

# Wait for Service to be assigned an external IP
echo "Waiting for PostgreSQL service to be assigned an external IP..."
kubectl wait --for=condition=available --timeout=300s deployment/postgresql

kubectl get svc postgresql-service -o wide

echo "Deployment complete! You can connect to PostgreSQL at the following IP:"
kubectl get svc postgresql-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

