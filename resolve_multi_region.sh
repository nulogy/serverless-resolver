#!/usr/local/bin/bash
#
# This script requires Bash 4 or 5: brew update && brew install bash

describe_regions() {
    aws ec2 describe-regions --output text --profile nulogy-anchor --region us-east-1 | cut -f3
}

create_role() {
    aws iam create-role --role-name "role-$(uuidgen)" --assume-role-policy-document file://policy.json | jq -r '.Role'
}

delete_role() {
    role_name="${1}"
    aws iam delete-role --role-name "${role_name}"
}

create_lambda() {
    role_arn="${1}"
    region="${2}"
    rm -f lambda_function.zip >/dev/null
    zip lambda_function.zip lambda_function.py >/dev/null
    lambda="$(aws lambda create-function --runtime python3.7 --role "${role_arn}" --zip-file 'fileb://lambda_function.zip' --function-name "lambda-$(uuidgen)" --handler 'lambda_function.lambda_handler' --region "${region}")"
    rm -f lambda_function.zip >/dev/null
    echo "${lambda}"
}

invoke_lambda() {
    function_name="${1}"
    region="${2}"
    hostname="${3}"
    aws lambda invoke --function-name "${function_name}" --region "${region}" --payload "{\"host\": \"${hostname}\"}" output.txt >/dev/null
    cat output.txt | jq -r
    rm -f output.txt >/dev/null
}

delete_lambda() {
    function_name="${1}"
    region="${2}"
    aws lambda delete-function --function-name "${function_name}" --region "${region}"
}

regions=($(describe_regions))

role="$(create_role)"
role_arn="$(echo "${role}" | jq -r '.Arn')"
role_name="$(echo "${role}" | jq -r '.RoleName')"

## sleep to avoid
## An error occurred (InvalidParameterValueException) when calling the CreateFunction operation: The role defined for the function cannot be assumed by Lambda.
sleep 10

hostname="${1}"

if [ -z "${hostname}" ] ; then
    echo "Usage: ${0} google.com"
    exit 1
fi

for region in "${regions[@]}"; do

    lambda="$(create_lambda "${role_arn}" "${region}")"
    lambda_name="$(echo "${lambda}" | jq -r '.FunctionName')"

    addr="$(invoke_lambda "${lambda_name}" "${region}" "${hostname}" | jq -r '.addr')"

    echo -e "${region}\t${hostname}\t${addr}"

    if [ -n "${lambda_name}" ] ; then
        delete_lambda "${lambda_name}" "${region}"
    fi

done

delete_role "${role_name}"
