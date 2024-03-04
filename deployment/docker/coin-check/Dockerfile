FROM golang:alpine as build

WORKDIR /coin-check

COPY . .

RUN apk update && apk upgrade && apk add --no-cache ca-certificates
RUN update-ca-certificates

RUN CGO_ENABLED=0 GOOS=linux go build -o bin/coin-check ./cmd/coin-check/main.go

FROM scratch

COPY --from=build /coin-check/bin/coin-check /bin/coin-check
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /bin

ENTRYPOINT ["/bin/coin-check"]

