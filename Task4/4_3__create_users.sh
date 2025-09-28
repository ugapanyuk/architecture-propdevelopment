#!/bin/bash

# Скрипт для создания пользователей Kubernetes через сертификаты x509

# Функция для создания пользователя
# $1 - Имя пользователя
# $2 - Группа пользователя
create_user() {
    local USER_NAME=$1
    local USER_GROUP=$2
    local KEY_FILE="users/${USER_NAME}.key"
    local CSR_FILE="users/${USER_NAME}.csr"

    echo "Создание пользователя: ${USER_NAME} в группе ${USER_GROUP}"

    # Создаем директорию для хранения ключей и сертификатов
    mkdir -p users

    # 1. Генерация приватного ключа
    openssl genrsa -out "${KEY_FILE}" 2048
    if [ $? -ne 0 ]; then echo "Ошибка: не удалось создать приватный ключ для ${USER_NAME}"; exit 1; fi
    echo "Приватный ключ создан: ${KEY_FILE}"

    # 2. Создание запроса на подпись сертификата (CSR)
    # CN (Common Name) - имя пользователя
    # O (Organization) - группа
    openssl req -new -key "${KEY_FILE}" -out "${CSR_FILE}" -subj "/CN=${USER_NAME}/O=${USER_GROUP}"
    if [ $? -ne 0 ]; then echo "Ошибка: не удалось создать CSR для ${USER_NAME}"; exit 1; fi
    echo "Запрос на подпись сертификата создан: ${CSR_FILE}"

    # 3. Подпись CSR с помощью CA кластера Minikube
    # Находим пути к CA кластера
    local KUBE_CA_CERT=$(minikube ssh "sudo cat /var/lib/minikube/certs/ca.crt")
    local KUBE_CA_KEY=$(minikube ssh "sudo cat /var/lib/minikube/certs/ca.key")

    if [ -z "$KUBE_CA_CERT" ] || [ -z "$KUBE_CA_KEY" ]; then
        echo "Ошибка: не удалось получить CA сертификат или ключ из Minikube."
        exit 1
    fi
    
    echo "$KUBE_CA_CERT" > users/ca.crt
    echo "$KUBE_CA_KEY" > users/ca.key

    # Подписываем сертификат
    openssl x509 -req -in "${CSR_FILE}" -CA users/ca.crt -CAkey users/ca.key \
    -CAcreateserial -out "users/${USER_NAME}.crt" -days 365
    if [ $? -ne 0 ]; then echo "Ошибка: не удалось подписать сертификат для ${USER_NAME}"; exit 1; fi
    echo "Сертификат подписан: users/${USER_NAME}.crt"
    
    # 4. Добавление учетных данных в kubeconfig
    kubectl config set-credentials "${USER_NAME}" \
    --client-certificate="users/${USER_NAME}.crt" \
    --client-key="${KEY_FILE}"
    echo "Учетные данные для ${USER_NAME} добавлены в kubeconfig."

    echo " Пользователь ${USER_NAME} успешно создан"
    echo ""
}

# --- Создаем пользователей согласно таблице ---

# Пользователь 1: Разработчик для домена "Продажи"
create_user "dev-ivan" "sales-developers"

# Пользователь 2: Оператор/SRE для домена "ЖКУ"
create_user "operator-anna" "tenants-operators"

# Пользователь 3: Менеджер/Аудитор с доступом только на чтение в домен "Финансы"
create_user "manager-maria" "auditors"

# Пользователь 4: Администратор кластера
create_user "admin-user" "cluster-admins"

