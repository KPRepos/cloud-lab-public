### Draft

#### Delete all deployments in all namespaces
echo "Deleting all deployments in all namespaces..."
for ns in $(kubectl get ns --no-headers | egrep -v "kube-system|kube-node-lease|kube-public" | awk '{print $1}'); do
  for deploy in $(kubectl get deployments -n "$ns" --no-headers | awk '{print $1}'); do
    kubectl delete deployment -n "$ns" "$deploy" || echo "Skipping $deploy in $ns as it's already deleted or not found"
  done
done

###
WEBHOOK_NAME="aws-load-balancer-webhook"
if kubectl get validatingwebhookconfigurations $WEBHOOK_NAME &> /dev/null; then
    echo "Found $WEBHOOK_NAME ValidatingWebhookConfiguration. Deleting..."
    kubectl delete validatingwebhookconfigurations $WEBHOOK_NAME
    echo "$WEBHOOK_NAME ValidatingWebhookConfiguration deleted."
else
    echo "$WEBHOOK_NAME ValidatingWebhookConfiguration not found. Skipping deletion."
fi

# Step 2: Loop through namespaces, excluding kube-system, kube-node-lease, and kube-public. Find Ingresses and remove finalizers.
for ns in $(kubectl get ns --no-headers | egrep -v "kube-system|kube-node-lease|kube-public" | awk '{print $1}'); do
    echo "Checking namespace: $ns"
    # Check if there are any Ingresses in the namespace before attempting patch
    if kubectl get ingress -n $ns &> /dev/null; then
        for ingress in $(kubectl get ingress --no-headers -n $ns | awk '{print $1}'); do
            echo "Found Ingress $ingress in namespace $ns. Removing finalizers..."
            kubectl patch ingress $ingress -n $ns -p '{"metadata":{"finalizers":[]}}' --type=merge && echo "Finalizers removed from Ingress $ingress in namespace $ns." || echo "Failed to remove finalizers from $ingress in $ns"
        done
    else
        echo "No Ingress resources found in namespace $ns."
    fi
done

#####


#### Get all namespaces except kube-system, kube-node-lease, and kube-public
namespaces=$(kubectl get ns --no-headers | egrep -v "kube-system|kube-node-lease|kube-public" | awk '{print $1}')

#### Loop through each namespace and delete all services
echo "Deleting all services in selected namespaces..."
for ns in $namespaces; do
  kubectl delete services --all -n "$ns" || echo "Skipping services in $ns as none found or an error occurred"
done

#### Loop through each namespace and delete all ingresses
echo "Deleting all ingresses in selected namespaces..."
for ns in $namespaces; do
  kubectl delete ingresses --all -n "$ns" --force --grace-period=0 || echo "Skipping ingresses in $ns as none found or an error occurred"
done
