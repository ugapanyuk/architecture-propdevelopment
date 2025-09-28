| Роль | Права роли | Группы пользователей |
| :--- | :--- | :--- |
| **`cluster-admin`** | Полный административный доступ ко всем ресурсам во всем кластере. Используется встроенная `ClusterRole`. | `cluster-admins` |
| **`namespace-operator`** | Полные права на управление всеми ресурсами (включая `secrets` и `exec` в подах) в рамках одного пространства имен (`Role`). | `sales-operators`, `tenants-operators`, `finance-operators` |
| **`namespace-developer`** | Права на управление рабочими нагрузками (Deployments, Services, ConfigMaps и т.д.) без доступа к `secrets` и RBAC-ресурсам. Действует в рамках одного пространства имен (`Role`). | `sales-developers`, `tenants-developers`, `finance-developers` |
| **`namespace-viewer`** | Права только на просмотр (`get`, `list`, `watch`) всех ресурсов, за исключением `secrets`. Действует в рамках одного пространства имен (`Role`). | `auditors`, `managers` |