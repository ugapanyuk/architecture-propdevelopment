#!/bin/bash

# Скрипт для создания пространств имен и ролей RBAC

echo "Создание пространств имен для бизнес-доменов"
kubectl create namespace sales --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace tenants --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace finance --dry-run=client -o yaml | kubectl apply -f -
echo "Пространства имен 'sales', 'tenants', 'finance' созданы или уже существуют."
echo ""

echo "Создание ClusterRole 'cluster-admin'"
echo "Будет использоваться встроенная ClusterRole 'cluster-admin'."
echo ""

echo "Создание Role 'namespace-viewer'"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-viewer
rules:
- apiGroups: ["", "apps", "autoscaling", "batch", "extensions", "policy", "networking.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
EOF
echo "Роль 'namespace-viewer' создана. Эта роль будет применяться в каждом namespace."
echo ""


echo "Создание Role 'namespace-developer'"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-developer
rules:
- apiGroups: ["", "apps", "autoscaling", "batch", "extensions", "policy", "networking.k8s.io"]
  resources:
  - pods
  - deployments
  - services
  - ingresses
  - networkpolicies
  - configmaps
  - persistentvolumeclaims
  - jobs
  - cronjobs
  - replicasets
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
echo "Роль 'namespace-developer' создана. Эта роль будет применяться в каждом namespace."
echo ""

echo "Создание Role 'namespace-operator'"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-operator
rules:
- apiGroups: ["", "apps", "autoscaling", "batch", "extensions", "policy", "networking.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Добавляем право на работу с secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Добавляем право на exec в поды
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
EOF
echo "Роль 'namespace-operator' создана. Эта роль будет применяться в каждом namespace."
echo ""
