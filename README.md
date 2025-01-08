# SSH Forum
A ssh forum, nothing more nothing less

## Features
- Anonymous text Forum
- Chat

## Installation
### Docker
You will need to have installed `git` and `docker`
```bash
git clone git@github.com:jfs-jfs/ssh-forum.git
cd ssh-forum
docker build -t ssh-forum . && docker run -d -p 2222:2222 ssh-forum
```

### Manual
You will need to have installed `dialog`, `go` and `git`
```bash
git clone git@github.com:jfs-jfs/ssh-forum.git
cd ssh-forum
go mod tidy && go build -v -o ssh-server server.go
./ssh-server # This will start the server at port 2222
```
