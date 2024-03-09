# MHA

The mha repo contains 2 services (coin-check, ok) which are deployed to AWS 
using Terraform. It also supports local development with Kind.

---
### Coin-check
---
The coin-check service exposes two endpoints:
- `/average` : which outputs a moving average of the bitcoin price in the last 
`MINUTES_POLL` period (default 10 min).
- `/current`: which outputs the price of bitcoin, updated in the last `SECONDS_POLL` 
period (default 10 sec).

For the average calculation, we are using a pre-allocated slice, which is 
calculated according to the values from the env vars set.
For the current calculation, we are writing to the same slice. It uses a FIFO
behaviour in order to keep up with the polling period and maintain the same
capacity throughout the life of the service.


|  Env var           | Description                                       | Default                                                                | 
|  -------------     | ------------------------------------------------- | ---------------------------------------------------------------------  |
|  `PORT`            | The port of the application.                      | `8080`                                                                 |
|  `PRICE_API`       | The api used for fetching coin price information. | `https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD`      |
|  `SECONDS_POLL`    | Interval of polling for the current coin price.   | `10`                                                                   |
|  `MINUTES_POLL`    | Interval of polling for the average coin price.   | `10`                                                                   |

---
### Ok
---
The ok service exposes one endpoint:
- `/ok` : which responds with a 200 status code when pinged.

|  Env var           | Description                                       | Default                                                                | 
|  -------------     | ------------------------------------------------- | ---------------------------------------------------------------------  |
|  `PORT`            | The port of the application.                      | `8081`                                                                 |

---
## Production deployment
---

### Prerequistes

- [Kubernetes]("https://kubernetes.io/docs/setup/")
- [Docker]("https://docs.docker.com/engine/install/ubuntu/")
- [Golang]("https://go.dev/doc/install")
- [AWS CLI]("https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html")
- [Terraform]("https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli") 

---

#### Steps to bring up the environment

There is no additional setup needed besides the [AWS CLI configuration]("https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html") with the 
correct access/secret keys and installing the prerequisites.

1) Initiate the cluster by `cd ./deployment/terraform/mha-cluster` and run
`terraform init`, `terraform plan` and `terraform apply`.

1) Deploy the k8s objects by `cd ./deployment/terraform/mha` and run
`terraform init`, `terraform plan` and `terraform apply`.

Querying the service can be done at the endpoint which is output after the `terraform
apply` step, which showcases the variable `k8s_service_ingress_elb`.

---

#### Deployment architecture


#### `mha-cluster`

We are storing the `terraform.tfstate` in an AWS S3 bucket. This way, we can query
necessary informations about the state of the cluster when we deploy the k8s objects.
This is done with a DynamoDB entry which holds the state lock and an S3 entry with 
the actual file.

We are provisioning the cluster with 2 add-ons. [VPC-CNI]("https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html")
for enabling `NetworkPolicy` rules inside our cluster. [EBS-CSI]("https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html")
for enabling volumes support.

RBAC is enabled in the cluster.

#### `mha`

We are using a private AWS ECR registry for our docker images.

We are fetching the `registry_password` secret, in order to configure the `imagePullSecret`
from AWS Secrets Manager. This assumes that we have a secret created beforehand with
the necessary credentials.

We are querying the S3 bucket that holds the `terraform.tfstate` to fetch cluster
information for the deployment.

#### `github-workflow`

Automated deployment process.

On PR, we are applying the `terraform plan` and showcasing it in the comments.

On merge, we are running the `terraform apply` automatically.

We have a Terraform Cloud workplace set with the AWS Access/Secret Keys. We 
provisioned the repo with the necessary secrets in order to interact with 
Terraform Cloud. 

---
## Local deployment
---

### Prerequisites

- [Kubernetes]("https://kubernetes.io/docs/setup/")
- [Docker]("https://docs.docker.com/engine/install/ubuntu/")
- [Golang]("https://go.dev/doc/install")
- [Kind]("https://kind.sigs.k8s.io/docs/user/quick-start/")
- [AWS CLI]("https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html") (optional) - if you want to pull the images from the private ECR repo
- [Terraform]("https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli") (optional) - if you want to apply part of the production setting 
to the local kind cluster
- [tfk8s]("https://github.com/jrhouston/tfk8s") (optional) - if you want to generate HCL files from the yaml charts

#### Development with docker
The docker configuration is found in `./deployment/docker/<service_name>`.
After making changes there, you can test the service by doing `make docker-coin-check`,
which will expose the service to `localhost:8000` and `localhost:8001` respectively.

#### Development with kind
The k8s/kind configuration is found in `./deployment/k8s/<service_name>` and the kind 
cluster configuration in `./deployment/k8s/kind-cluster.yaml`.

#### Development with terraform
The terraform configuration is found in `./deployment/terraform/<service_name>-local`.
If you configured the cloud custer, everything should work with the usual `init`,
`plan` and `apply` commands.

---

#### Steps to bring up the environment

The cluster is configured to support an nginx ingress, hostname resolution. 
RBAC is enabled by default in Kind. The cluster configuration is found at 
`./deployment/k8s/kind-cluster.yaml`.

1) Install the necessary prerequisites. 
The cluster can be brought up with `make kind-cluster-up`. 

2) Run `make kind-local-up`, which will create a local custom k8s cluster, build 
the docker service containers, load them into kind and create an nginx-ingress-controller.


The `coin-check` service will have the port exposed on `localhost:30000` and the 
`ok` service will have the port exposed on `localhost:30001`. If you set up the 
`hostname` in the ingress, the services can be pinged at `hello.coin-check.com` 
and `hello.ok.com`.

---

*OPTIONAL STEPS*:

1) If you are pulling the docker images from the AWS ECR Registry you will need
to run `make aws-log-in` and afterwards `make aws-imagePull`. The `~/.aws/credentials` 
need to be set beforehand.

2) If you are using `hostname` in the ingress, you will need to run `make kind-local-ingress-host`
and add the IP to your `/etc/hosts`.

3) If you are deploying locally using Terraform, you will need to set the `host`,
`client_certificate`, `cluster_ca_certificate` and `client_key` in a `secrets.tfvars` file.
You provide the `.tfvars` file to the tf commands with the flag `-var-file=<file>.tfvars`.
You can see the variables by running `make kind-cred-info`. 

4) If you pull the images from ECR in the Terraform configuration, you will need to add to the same 
to add the `registry_server`, `registry_username`, `registry_password` and 
`registry_email` to the `secrets.tfvars` file.

---

*TODOs*

- Less hardcoded variables in the terraform configurations.
- Less hardcoded variables in the k8s configuration. Maybe opt for helm charts.
- Clearer k8s deployment with proper namespaces.
