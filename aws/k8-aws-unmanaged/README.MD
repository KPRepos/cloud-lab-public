## End2End k8 deployment within AWS for 1 Control plane and Multiple Worker Nodes (ubuntu)

#### Deploy a test k8 cluster in AWS under 7 minutes, using SPOT instances for worker nodes.

### Connect to Controlplane using SSM and Run kubectl 

#### No ec2 keys required

#### Steps:-

1) Update `deploy-fule.auto.tfvars` per requirement
2) Run `terraform init`, `terraform plan`, validate and apply via `terraform apply`
3) Login to AWS console, ec2-->instance--> k8-ct1-->connect->Sessionmanager
   
   if have aws tools locally installed, also via cli 

   aws ssm start-session --target $(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8-ct1" --query "Reservations[*].Instances[*].InstanceId" --output text)

4) Access k8admin user and run kubectl 

`sudo su - k8admin` and run `kubectl get nodes`

5) cat kubeconfig to copy kubeconfig to your local terminal and run `kubectl'



##### Pending/Future:- 

1) Authentication 
2) Ingress LB Integration (Nginx or AWS LB)
3) Currently Auto deploymenet code deploys 1CT and Multipel Worker Nodes, Plans to add Multiple CT's
4) Links to Used-Blogs-For-Referance-and-Code

##### Notes:-

1) K8 CT requires min 1700Mb ram so skipped pre-checks just in case if instances are nano or micro
2) After logging via SSM - Below to test userdata 
sudo cat /var/log/cloud-init-output.log
sudo tail -f /var/log/cloud-init-output.log
3) Classic LB for now as nlb not required for lab testing




