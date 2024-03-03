FROM golang:1.22 as build

WORKDIR /coin-check

COPY . .

RUN go build -o bin/coin-check ./cmd/coin-check/main.go

FROM scratch 

COPY --from=build /coin-check/bin/coin-check /bin/coin-check

WORKDIR /bin

ENTRYPOINT ["/bin/coin-check"]

