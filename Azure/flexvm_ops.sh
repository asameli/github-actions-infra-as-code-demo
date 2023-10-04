#!/bin/bash

# Authenticate and get token
AUTH_RESPONSE=$(curl -s -X POST "https://api.fortinet.com/flex/api/v1/auth" -H "accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&grant_type=client_credentials&tenant_id=$TENANT_ID")
AUTH_STATUS=$(echo $AUTH_RESPONSE | jq -r '.status')
if [[ "$AUTH_STATUS" != "success" ]]; then
  echo "Authentication failed"
  exit 1
fi
ACCESS_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.access_token')

# List configurations
CONFIG_RESPONSE=$(curl -s -X GET "https://api.fortinet.com/flex/api/v1/tenants/$TENANT_ID/configs" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")
if ! CONFIG_STATUS=$(echo $CONFIG_RESPONSE | jq -r '.status' 2>/dev/null); then
  echo "Failed to parse configuration status"
  exit 1
fi
if [[ "$CONFIG_STATUS" != "0" ]]; then
  echo "Failed to list configurations"
  exit 1
fi
CONFIG_ID=$(echo $CONFIG_RESPONSE | jq -r '.configs[0].id')

# List VMs
VM_RESPONSE=$(curl -s -X GET "https://api.fortinet.com/flex/api/v1/tenants/$TENANT_ID/vms?configId=$CONFIG_ID" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")
if ! VM_STATUS=$(echo $VM_RESPONSE | jq -r '.status' 2>/dev/null); then
  echo "Failed to parse VM status"
  exit 1
fi
if [[ "$VM_STATUS" != "0" ]]; then
  echo "Failed to list VMs"
  exit 1
fi
VM_TOKEN=$(echo $VM_RESPONSE | jq -r '.vms[0].token')

# Activate VM
ACTIVATE_VM_RESPONSE=$(curl -s -X POST "https://api.fortinet.com/flex/api/v1/tenants/$TENANT_ID/vms/$VM_TOKEN/activate" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")
if ! ACTIVATE_VM_STATUS=$(echo $ACTIVATE_VM_RESPONSE | jq -r '.status' 2>/dev/null); then
  echo "Failed to parse VM activation status"
  exit 1
fi
if [[ "$ACTIVATE_VM_STATUS" != "0" ]]; then
  echo "Failed to activate VM"
  exit 1
fi

echo "VM activated successfully"
