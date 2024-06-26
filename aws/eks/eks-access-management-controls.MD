#### Ref:- https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/

##### Code already automates this, below is just for ref for manual approach. 

#### EKS Version >=1.23 and AWSCLi is Latest

### Example commands/Process to provide Access to an SSO User via EKS Controls using default Policy 


#### Check AWS CLI and supported Policies

`aws eks list-access-policies --region us-west-2`

`aws eks list-access-entries  --cluster-name  dev-eks1 --region us-west-2`

#### Update Cluster to use API Mode along with Config mode

`aws eks update-cluster-config --name eks-lab1 --region us-west-2 --access-config authenticationMode=API_AND_CONFIG_MAP`

#### Check Status 

`aws eks describe-cluster --name eks-lab1 --region us-west-2 --query "cluster.status"`

#### Add Entry 

`aws eks create-access-entry --cluster-name eks-lab1 --principal-arn "arn:aws:iam::1234567890:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSPowerUserAccess_11111aaaaaa"`

#### Associate Policy 

`aws eks associate-access-policy --cluster-name eks-lab1 --principal-arn "arn:aws:iam::1234567890:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSPowerUserAccess_11111aaaaaa" --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster`

