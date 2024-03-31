### Kubeconfig

export KUBECONFIG=./config-homelab 
kubectl get pods -A


### Delete a struck terminating Namspace 

`kubectl proxy` in one terminal

`kubectl get ns delete-me -o json | \
  jq '.spec.finalizers=[]' | \
  curl -X PUT http://localhost:8001/api/v1/namespaces/delete-me/finalize -H "Content-Type: application/json" --data @-`

On-line command:-

(
NAMESPACE=your-rogue-namespace
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
)


### Logs


### Proxy

#### Node Labels 

kubectl label nodes k8-n2-homelab name=k8-n2-homelab

#### Kubectl
systemctl status kubelet
journalctl -u kubelet -xe

#### Calico

kubectl logs -n kube-system calico-node-xxxxx -c calico-node
kubectl logs -n kube-system calico-node-xxxxx -c calico-node --previous






