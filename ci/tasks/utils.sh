#!/usr/bin/env bash

get_stack_info() {
  stack_name=$1
  return $(aws cloudformation describe-stacks --stack-name ${stack_name})
}

get_stack_info_of() {
  local base_os=$1
  local key=$2
  local stack_name=$3

  stack_info=get_stack_info $stack_name
  return $( echo ${stack_info} | \
          jq --arg base_os ${base_os} --arg key ${key} \
          '.Stacks[].Outputs[] | select(.OutputKey=="\($base_os)\($key)").OutputValue' )
}

get_stack_status() {
  local stack_name=$1

  stack_info=get_stack_info $stack_name
  return $( echo ${stack_info} | jq '.Stacks[].StackStatus' )
}

check_param() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == 'replace-me' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}

print_git_state() {
  echo "--> last commit..."
  TERM=xterm-256color git log -1
  echo "---"
  echo "--> local changes (e.g., from 'fly execute')..."
  TERM=xterm-256color git status --verbose
  echo "---"
}

check_for_rogue_vm() {
  local ip=$1
  set +e
  nc -vz -w10 $ip 22
  status=$?
  set -e
  if [ "${status}" == "0" ]; then
    echo "aborting due to vm existing at ${ip}"
    exit 1
  fi
}
