export OWNER="thomas-enjalbert"
export RESOURCE_GROUP="tenjalbertRG"
export STORAGE_ACCOUNT="rmstate$(IFS=' -' read -r p n <<< "$OWNER"; echo "${p:0:2}${n:0:2}")tf"
export LOCATION="francecentral"
export CONTAINER="tfstate-ads"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

az storage account create \
  --name           "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location       "$LOCATION" \
  --sku            Standard_LRS

sleep 15

az storage container create \
  --name         "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT"

az storage blob list \
  --container-name "$CONTAINER" \
  --account-name   "$STORAGE_ACCOUNT" \
  --output         table

sleep 15

cd terraform

terraform init \
  -backend-config="resource_group_name=${RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${STORAGE_ACCOUNT}" \
  -backend-config="container_name=$CONTAINER" \
  -backend-config="key=${OWNER}.terraform.tfstate" \
  -migrate-state