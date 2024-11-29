#!/bin/bash

while true; do
  echo "Dummy service is running..." | logger -t dummy-service
  sleep 10
done