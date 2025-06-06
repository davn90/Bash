#!/bin/bash

file=$1

vault kv put -tls-skip-verify kv/application @${file}
