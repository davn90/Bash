#!/bin/bash

file=$1

vault kv get -field=data -format=json -tls-skip-verify kv/application > ${file}
