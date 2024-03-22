## Draft

# Delete all deployments in all namespaces
echo "Deleting all deployments in all namespaces..."
kubectl delete deployments --all --all-namespaces

# Delete all services in all namespaces (this includes Load Balancers)
echo "Deleting all services in all namespaces..."
kubectl delete services --all --all-namespaces

# Delete all ingresses in all namespaces
echo "Deleting all ingresses in all namespaces..."
kubectl delete ingresses --all --all-namespaces
