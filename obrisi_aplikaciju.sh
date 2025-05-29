#!/bin/bash

docker-compose down -v --rmi all --remove-orphans

echo "Aplikacija je potpuno obrisana."
