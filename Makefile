###############################################################################
# Local go setup

go-coin-check:
	go run ./cmd/coin-check/main.go

go-ok:
	go run ./cmd/ok/main.go

###############################################################################
# Local docker setup

docker-local-up: docker-coin-check-up docker-ok-up

docker-coin-check-up:
	docker-coin-check-build
	docker run --rm -d --name coin-check -p 8080:8080 -d coin-check

docker-coin-check-build:
	docker build -f ./deployment/docker/coin-check/Dockerfile -t coin-check .

docker-ok-up:
	docker-ok-build
	docker run --rm -d --name ok -p 8081:8081 -d ok

docker-ok-build:
	docker build -f ./deployment/docker/ok/Dockerfile -t ok .

docker-down:
	docker stop $(docker ps -qa)

###############################################################################
# Local k8s setup

kind-local-up: kind-cluster-up kind-coin-check kind-ok

kind-cluster-up:
	kind create cluster --name mha --config=./deployment/k8s/kind-config.yaml

kind-cluster-down:
	kind delete cluster --name mha

kind-coin-check:
	docker-coin-check-build
	kind load docker-image coin-check:latest
	kubectl apply -f ./deployment/k8s/coin-check/coin-check.yaml
	kubectl apply -f ./deployment/k8s/coin-check/service.yaml

kind-ok:
	docker-ok-build
	kind load docker-image ok:latest
	kubectl apply -f ./deployment/k8s/ok/ok.yaml
	kubectl apply -f ./deployment/k8s/ok/service.yaml

kind-down:
	kubectl delete deployment coin-check
	kubectl delete svc coin-check
	kubectl delete deployment ok
	kubectl delete svc ok

kind-cred-info:
	kubectl config view --minify --flatten --context=kind-mha

###############################################################################
# Local terraform setup

tf-k8s-to-hcl:
	cat ./deployment/k8s/coin-check/service.yaml | tfk8s >> ./deployment/terraform/coin-check/kubernetes.tf

tf-cluster-creds:
	cd ./deployment/terraform/mha-cluster/ && \
	aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)

###############################################################################
# Local aws setup

# TODO: Save the AWS registry as a variable.

aws-log-in:
	aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 198760508209.dkr.ecr.eu-west-3.amazonaws.com

aws-imagePull:
	ECR_PASS=$(shell sh -c "aws ecr get-login-password --region eu-west-3") && \
	kubectl create secret docker-registry reg-aws --docker-server=198760508209.dkr.ecr.eu-west-3.amazonaws.com --docker-username=AWS --docker-password="$$ECR_PASS" --docker-email=bogdanbojan03@gmail.com

