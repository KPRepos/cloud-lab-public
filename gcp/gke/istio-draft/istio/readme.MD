


kubectl label namespace nginx-apps-public istio-injection=enabled

kubectl label namespace nginx-apps-private istio-injection=enabled

kubectl get services -n nginx-apps-public -o wide
kubectl get services -n nginx-apps-private -o wide
kubectl get services --all-namespaces -o wide | grep LoadBalancer

kubectl get gateways.networking.istio.io --all-namespaces
NAMESPACE            NAME                   AGE
nginx-apps-private   private-gateway        34m
nginx-apps-public    nginx-public-gateway   17m