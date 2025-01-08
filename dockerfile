FROM golang:1.23.0

ENV TERM=xterm-256color

RUN apt update && apt upgrade -y
RUN apt install dialog

WORKDIR /usr/src/app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN go build -v -o ssh-server server.go

CMD ["./ssh-server"]
