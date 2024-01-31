https://istio.io/latest/docs/setup/install/helm/

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default
helm ls -n istio-system

skipped istio CNI 

helm install istiod istio/istiod -n istio-system --wait

helm ls -n istio-system

helm status istiod -n istio-system
kubectl get deployments -n istio-system --output wide



https://istio.io/latest/docs/setup/additional-setup/gateway/

kubectl create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress --wait


### If less CPU 

helm install istio-ingressgateway istio/gateway \
  --set resources.requests.cpu=100m \
  --set resources.limits.cpu=200m


##### For private GKE clusters

An automatically created firewall rule does not open port 15017. This is needed by the Pilot discovery validation webhook.

To review this firewall rule for master access:

$ gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"

gcloud compute firewall-rules list --filter="name~gke-kp-lab-k8-[0-9a-z]*-master"

To replace the existing rule and allow master access:

$ gcloud compute firewall-rules update gke-kp-lab-k8-c7b092dc-master --allow tcp:10250,tcp:443,tcp:15017
#####

Example
https://istio.io/latest/docs/examples/bookinfo/


kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml


kubectl apply -f  https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl get services
kubectl get pods

kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"



#Prereq - kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/master/config/crd/bases


kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/gateway-api/bookinfo-gateway.yaml

kubectl wait --for=condition=programmed gtw bookinfo-gateway

export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"


kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo-versions.yaml




kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

istioctl dashboard kiali

https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml