#!/bin/bash

docker-compose build

docker volume create db_data

docker network create app-network

echo "Aplikacija je pripremljena!"
