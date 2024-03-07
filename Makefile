###############################################################################
# Local go setup

go-coin-check:
	go run ./cmd/coin-check/main.go

go-ok:
	go run ./cmd/ok/main.go

###############################################################################
# Local docker setup

docker-coin-check:
	docker build -f ./deployment/docker/coin-check/Dockerfile -t coin-check .
	docker run --rm -d --name coin-check -p 8080:8080 -d coin-check

docker-ok:
	docker build -f ./deployment/docker/ok/Dockerfile -t ok .
	docker run --rm -d --name ok -p 8081:8080 -d ok

docker-down:
	docker stop $(docker ps -qa)

###############################################################################
# Local k8s setup

kind-cluster-up:
	kind create cluster --config=./deployment/k8s/kind-config.yaml

kind-cluster-down:
	kind delete cluster

# TODO: Make only one setup for the service so as to not have duplicate code.
kind-coin-check:
	kind load docker-image coin-check:latest
	kubectl apply -f ./deployment/k8s/coin-check/coin-check.yaml
	kubectl apply -f ./deployment/k8s/coin-check/service.yaml

kind-ok:
	kind load docker-image ok:latest
	kubectl apply -f ./deployment/k8s/ok/ok.yaml
	kubectl apply -f ./deployment/k8s/ok/service.yaml

kind-down:
	kubectl delete deployment coin-check
	kubectl delete svc coin-check
	kubectl delete deployment ok
	kubectl delete svc ok

