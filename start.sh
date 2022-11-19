#!/bin/bash

docker stop analogcity
docker build -t analogimg .
docker run -d --rm --name analogcity -p22:22 -v $(pwd)/data.db:/lowlife/data.db:rw analogimg

