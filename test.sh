#!/usr/local/bin/bash
#
# This script requires Bash 4 or 5: brew update && brew install bash

docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_DEFAULT_REGION -v "$PWD":/var/task lambci/lambda:python3.7 lambda_function.lambda_handler '{"host": "google.com"}'
rm -f __pycache__
