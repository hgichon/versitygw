#!/usr/bin/env bash

# Copyright 2024 Versity Software
# This file is licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

check_object_lock_config() {
  log 6 "check_object_lock_config"
  if ! check_param_count "check_object_lock_config" "bucket" 1 $#; then
    return 1
  fi
  lock_config_exists=true
  if ! get_object_lock_configuration "rest" "$1"; then
    # shellcheck disable=SC2154
    log 5 "lock config error: $get_object_lock_config_err"
    if [[ "$get_object_lock_config_err" == *"does not exist"* ]]; then
      # shellcheck disable=SC2034
      lock_config_exists=false
    else
      log 2 "error getting object lock config"
      return 1
    fi
  fi
  return 0
}

check_no_object_lock_config_rest() {
  if ! check_param_count "check_no_object_lock_config_rest" "bucket" 1 $#; then
    return 1
  fi
  if get_object_lock_configuration_rest "$1"; then
    log 2 "object lock config should be missing"
    return 1
  fi
  log 5 "object lock config: $(cat "$TEST_FILE_FOLDER/object-lock-config.txt")"
  # shellcheck disable=SC2154
  if [[ "$result" != "404" ]]; then
    log 2 "incorrect response code: $reply"
    return 1
  fi
  if ! error=$(xmllint --xpath '//*[local-name()="Code"]/text()' "$TEST_FILE_FOLDER/object-lock-config.txt" 2>&1); then
    log 2 "error getting object lock config error: $error"
    return 1
  fi
  if [[ "$error" != "ObjectLockConfigurationNotFoundError" ]]; then
    log 2 "unexpected error: $error"
    return 1
  fi
  return 0
}

check_object_lock_config_enabled_rest() {
  if ! check_param_count "check_object_lock_config_enabled_rest" "bucket" 1 $#; then
    return 1
  fi
  if ! get_object_lock_configuration_rest "$1"; then
    log 2 "error getting object lock config"
    return 1
  fi
  log 5 "object lock config: $(cat "$TEST_FILE_FOLDER/object-lock-config.txt")"
  if ! enabled=$(xmllint --xpath '//*[local-name()="ObjectLockEnabled"]/text()' "$TEST_FILE_FOLDER/object-lock-config.txt" 2>&1); then
    log 2 "error getting object lock config enabled value: $enabled"
    return 1
  fi
  if [[ "$enabled" != "Enabled" ]]; then
    log 2 "expected 'Enabled', is $enabled"
    return 1
  fi
  return 0
}

