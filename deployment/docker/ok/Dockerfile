FROM golang:1.22 as build

WORKDIR /ok

COPY . .

RUN go build -o bin/ok ./cmd/ok/main.go

FROM scratch 

COPY --from=build /ok/bin/ok /bin/ok

WORKDIR /bin

ENTRYPOINT ["/bin/ok"]

