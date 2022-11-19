#!/bin/bash

docker stop analogcity
docker build -t analogimg .
docker run -d --rm --name analogcity -p2222:22 -v $(pwd)/data.db:/lowlife/data.db:rw analogimg

