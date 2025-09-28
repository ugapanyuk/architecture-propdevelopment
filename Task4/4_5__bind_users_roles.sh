#!/bin/bash

echo "Привязка группы 'cluster-admins' к ClusterRole 'cluster-admin'"
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --group=cluster-admins \
  --dry-run=client -o yaml | kubectl apply -f -
echo "ClusterRoleBinding 'cluster-admin-binding' создан."
echo ""


echo "Настройка привязок для namespace 'sales'"
# dev-ivan (группа sales-developers) получает роль namespace-developer в namespace sales
kubectl create rolebinding sales-developer-binding \
  --clusterrole=namespace-developer \
  --group=sales-developers \
  --namespace=sales \
  --dry-run=client -o yaml | kubectl apply -f -
echo "RoleBinding 'sales-developer-binding' создан."
echo ""


echo "Настройка привязок для namespace 'tenants'"
# operator-anna (группа tenants-operators) получает роль namespace-operator в namespace tenants
kubectl create rolebinding tenants-operator-binding \
  --clusterrole=namespace-operator \
  --group=tenants-operators \
  --namespace=tenants \
  --dry-run=client -o yaml | kubectl apply -f -
echo "RoleBinding 'tenants-operator-binding' создан."
echo ""


echo "Настройка привязок для namespace 'finance'"
# manager-maria (группа auditors) получает роль namespace-viewer в namespace finance
kubectl create rolebinding finance-viewer-binding \
  --clusterrole=namespace-viewer \
  --group=auditors \
  --namespace=finance \
  --dry-run=client -o yaml | kubectl apply -f -
echo "RoleBinding 'finance-viewer-binding' создан."
echo ""

