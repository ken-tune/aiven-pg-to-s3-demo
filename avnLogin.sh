#!/bin/bash

source aivenToken.sh
echo $TF_VAR_aiven_api_token | pbcopy

echo Token is in your clipboard - just command-v to paste

avn user login ken.tune@aiven.io --token


