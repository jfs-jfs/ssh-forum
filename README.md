# AnalgoCity forum
An ssh forum, nothing more nothing less

## Installation
### Docker Install

#### From Docker Hub image
Grab the database and configuration
```bash
wget https://raw.githubusercontent.com/analogcity/analogcity/master/clean_database.db
wget https://raw.githubusercontent.com/analogcity/analogcity/master/config
```

Edit the configuration to your liking and start a container
```bash
docker run \
    --rm -d -p2222:22 \
    -v $(pwd)/clean_database.db:/lowlife/data.db \
    analogcity/ssh_forum:latest
```

#### From cloned repo
Clone this repo
```bash
git clone https://github.com/analogcity/ssh-forum && cd analogcity
```
Build the image
```bash
docker build -t analogcity .
```

Edit the configuration to your liking and start a container
```bash
docker run \
    --rm -d -p2222:22 \
    -v $(pwd)/clean_database.db:/lowlife/data.db \
    analogcity
```

### Manual install
Check the docker file and try to do it on your system :)

## Access it
```bash
ssh -p2222 lowlife@localhost
```
