#!/bin/bash

NAMESPACE="network-policy-demo"
POLICY_FILE="non-admin-api-allow.yaml"

echo "Создание namespace '${NAMESPACE}'"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
echo ""

echo "Развертывание 4-х Nginx сервисов с метками"
kubectl run front-end-app --image=nginx --labels role=front-end --namespace=${NAMESPACE} --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --namespace=${NAMESPACE} --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --namespace=${NAMESPACE} --expose --port 80
kubectl run admin-back-end-app --image=nginx --labels role=admin-back-end-api --namespace=${NAMESPACE} --expose --port 80

echo "Ожидание готовности подов..."
kubectl wait --for=condition=ready pod -l role -n ${NAMESPACE} --timeout=120s
echo "Все сервисы развернуты."
echo ""

#Создание единого файла сетевой политики 
echo "Создание файла '${POLICY_FILE}'"

# Этот файл будет содержать три политики, разделенные '---'
# 1. Запретить весь входящий трафик к API по умолчанию.
# 2. Разрешить трафик от front-end к back-end-api.
# 3. Разрешить трафик от admin-front-end к admin-back-end-api.

cat <<EOF > ${POLICY_FILE}
# ПОЛИТИКА 1: Запретить весь входящий трафик к API по умолчанию
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-default-deny-ingress
  namespace: ${NAMESPACE}
spec:
  podSelector:
    matchExpressions:
      - {key: role, operator: In, values: [back-end-api, admin-back-end-api]}
  policyTypes:
  - Ingress
  ingress: [] # Пустой ingress означает "запретить все"
---
# ПОЛИТИКА 2: Разрешить трафик от front-end к back-end-api
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-non-admin-api-access
  namespace: ${NAMESPACE}
spec:
  podSelector:
    matchLabels:
      role: back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: front-end
    ports:
    - protocol: TCP
      port: 80
---
# ПОЛИТИКА 3: Разрешить трафик от admin-front-end к admin-back-end-api
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-admin-api-access
  namespace: ${NAMESPACE}
spec:
  podSelector:
    matchLabels:
      role: admin-back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: admin-front-end
    ports:
    - protocol: TCP
      port: 80
EOF

echo "Файл '${POLICY_FILE}' успешно создан."
echo ""

echo "Применение сетевой политики из файла '${POLICY_FILE}'"
kubectl apply -f ${POLICY_FILE}
echo "Сетевая политика применена."
echo ""

echo "Проверка сетевой связности"
echo "Политики применены. Ожидание несколько секунд для их вступления в силу..."
sleep 5

# Функция для проверки
# $1 - Имя пода-источника
# $2 - Имя сервиса-получателя
# $3 - Ожидаемый результат (pass/fail)
run_test() {
    local source_pod_role=$1
    local target_service=$2
    local expected=$3

    echo -n "Проверка: от пода с ролью '${source_pod_role}' -> к сервису '${target_service}'... "

    local result=$(kubectl run test-$RANDOM --rm -i -t --image=alpine --namespace=${NAMESPACE} --overrides='{"spec": {"nodeSelector": {"kubernetes.io/os": "linux"}}}' -- sh -c "wget -qO- --timeout=2 http://${target_service}" 2>/dev/null)

    if [[ ${result} == *"Welcome to nginx!"* && ${expected} == "pass" ]]; then
        echo "OK (Трафик разрешен, как и ожидалось)"
    elif [[ -z ${result} && ${expected} == "fail" ]]; then
        echo "OK (Трафик заблокирован, как и ожидалось)"
    else
        echo "ОШИБКА! Неожиданный результат."
        if [[ ${expected} == "pass" ]]; then
            echo "Ожидался разрешенный трафик, но он был заблокирован."
        else
            echo "Ожидался заблокированный трафик, но он был разрешен."
        fi
    fi
}

run_exec_test() {
    local source_pod_app_name=$1
    local target_service_app_name=$2
    local expected=$3

    echo -n "Проверка: от ${source_pod_app_name} -> к ${target_service_app_name}... "
    
    local result=$(kubectl exec -n ${NAMESPACE} deploy/${source_pod_app_name} -- wget -qO- --timeout=2 http://${target_service_app_name})
    
    if [[ ${result} == *"Welcome to nginx!"* && ${expected} == "pass" ]]; then
        echo "OK (Трафик разрешен, как и ожидалось)"
    elif [[ -z ${result} && ${expected} == "fail" ]]; then
        echo "OK (Трафик заблокирован, как и ожидалось)"
    else
        echo "ОШИБКА! Неожиданный результат."
        if [[ ${expected} == "pass" ]]; then
            echo "Ожидался разрешенный трафик, но он был заблокирован."
        else
            echo "Ожидался заблокированный трафик, но он был разрешен."
        fi
    fi
}


echo "Тестирование РАЗРЕШЕННЫХ соединений"
run_exec_test "front-end-app" "back-end-api-app" "pass"
run_exec_test "admin-front-end-app" "admin-back-end-app" "pass"
echo ""

echo "Тестирование ЗАПРЕЩЕННЫХ соединений (кросс-трафик)"
run_exec_test "front-end-app" "admin-back-end-app" "fail"
run_exec_test "admin-front-end-app" "back-end-api-app" "fail"
echo ""

# Для очистки ресурсов 
#kubectl delete namespace ${NAMESPACE}

