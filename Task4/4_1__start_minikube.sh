#!/bin/bash

# Проверка, что minikube установлен
if ! command -v minikube &> /dev/null
then
    echo "Ошибка: minikube не найден. Пожалуйста, установите Minikube."
    exit 1
fi

# Проверка статуса minikube
STATUS=$(minikube status -f "{{.Host}}")

if [ "$STATUS" == "Running" ]; then
    echo "Minikube уже запущен."
else
    echo "Запускаем Minikube..."
    minikube start
    if [ $? -eq 0 ]; then
        echo "Minikube успешно запущен."
    else
        echo "Ошибка при запуске Minikube."
        exit 1
    fi
fi

echo "Проверяем статус кластера:"
kubectl cluster-info
