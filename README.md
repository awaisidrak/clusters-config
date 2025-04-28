# clusters-config
mongodb , rabbitmq and monitoring stack configurations.
helm chart commadn to execute the kubernetes cluster of differnet services 

  monitoring-stack config

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

1.  helm install/upgrade prom prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
    helm upgrade --install prom prometheus-community/kube-prometheus-stack   -n monitoring -f values.yaml

2. helm install/upgrade alertmanager prometheus-community/alertmanager   -n monitoring -f values.yml

3. helm install/upgrade redis-exporter prometheus-community/prometheus-redis-exporter -n monitoring -f values.yaml

4. helm upgrade --install rabbitmq-exporter prometheus-community/prometheus-rabbitmq-exporter -n monitoring -f values.y
   helm install rabbitmq-exporter prometheus-community/prometheus-rabbitmq-exporter -n monitoring -f values.yml

5. helm upgrade/install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -n monitoring -f values.yml


application-stack 
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update

1.  helm install mongodb oci://registry-1.docker.io/bitnamicharts/mongodb --namespace v8bot --create-namespace -f values.yml

2. helm install my-redis oci://registry-1.docker.io/bitnamicharts/redis   -f values.yml   --namespace v8bot   --create-namespace

3.  helm install my-rabbitmq oci://registry-1.docker.io/bitnamicharts/rabbitmq   -f values.yml   --namespace mongodb   --create-namespace

