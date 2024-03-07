###############################################################################
# Local go setup

go-coin-check:
	go run ./cmd/coin-check/main.go

go-ok:
	go run ./cmd/ok/main.go

	docker build -f ./deployment/docker/coin-check/Dockerfile -t coin-check .
	docker run --rm -d --name coin-check -p 8080:8080 -d coin-check
ok:
	docker build -f ./deployment/docker/ok/Dockerfile -t ok .
	docker run --rm -d --name ok -p 8081:8080 -d ok

down:
	docker stop $(docker ps -qa)

