###############################################################################
# Local go setup

go-coin-check:
	go run ./cmd/coin-check/main.go

go-ok:
	go run ./cmd/ok/main.go

###############################################################################
# Local docker setup

docker-local-up: docker-coin-check-up docker-ok-up

docker-coin-check-up: docker-coin-check-build
	docker run --rm -d --name coin-check -p 8080:8080 -d coin-check

docker-coin-check-build:
	docker build -f ./deployment/docker/coin-check/Dockerfile -t coin-check .

docker-ok-up: docker-ok-build
	docker run --rm -d --name ok -p 8081:8081 -d ok

docker-ok-build:
	docker build -f ./deployment/docker/ok/Dockerfile -t ok .

docker-down:
	docker stop $(docker ps -qa)

###############################################################################
# Local k8s setup

kind-local-up: kind-cluster-up kind-local-ingress kind-coin-check kind-ok

kind-cluster-up:
	kind create cluster --name mha --config=./deployment/k8s/kind-config.yaml

kind-cluster-down:
	kind delete cluster --name mha

kind-coin-check: docker-coin-check-build
	kind load docker-image coin-check:latest --name "mha"
	kubectl apply -f ./deployment/k8s/coin-check/.

kind-local-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=90s

kind-local-ingress-host:
	docker container inspect mha-control-plane \
	--format '{{ .NetworkSettings.Networks.kind.IPAddress }}'

kind-ok: docker-ok-build
	kind load docker-image ok:latest --name "mha"
	kubectl apply -f ./deployment/k8s/ok/.

kind-down:
	kubectl delete -f ./deployment/k8s/coin-check/.
	kubectl delete -f ./deployment/k8s/ok/.

kind-cred-info:
	kubectl config view --minify --flatten --context=kind-mha

###############################################################################
# Local helm setup

helm-coin-check-up:
	helm install ./deployment/helm/coin-check --name-template coin-check

helm-coin-check-down:
	helm uninstall coin-check

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

aws-log-in:
	aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 198760508209.dkr.ecr.eu-west-3.amazonaws.com

aws-imagePull:
	ECR_PASS=$(shell sh -c "aws ecr get-login-password --region eu-west-3") && \
	kubectl create secret docker-registry reg-aws --docker-server=198760508209.dkr.ecr.eu-west-3.amazonaws.com --docker-username=AWS --docker-password="$$ECR_PASS" --docker-email=bogdanbojan03@gmail.com

aws-ecr-push-images: docker-ok-build docker-coin-check-build aws-log-in
	docker push 198760508209.dkr.ecr.eu-west-3.amazonaws.com/ok:latest
	docker push 198760508209.dkr.ecr.eu-west-3.amazonaws.com/coin-check:latest

###############################################################################
# Helpers
# aws eks update-kubeconfig --region eu-west-3 --name <cluster_name>
# kubectl config get-contexts
# kubectl config use-context kind-mha
# kubectl run busybox1 --image=busybox --labels app=busybox1 -- sleep 3600
# kubectl exec -ti busybox1 -- ping -c3 <coin_check_ip>
