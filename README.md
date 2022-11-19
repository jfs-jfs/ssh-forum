# AnalgoCity forum
An ssh forum, nothing more nothing less

## Docker Install
Clone this repo

```bash
git clone https://github.com/analogcity/analogcity && cd analogcity
```
Build the image

```bash
docker build -t analogcity .
```
Start the container

```bash
docker run -p<port you want to run it>:22 -v $(pwd)/clean_database.db:/lowlife/data.db analogcity
```

## Manual install
Check the docker file and try to do it on your system :)
