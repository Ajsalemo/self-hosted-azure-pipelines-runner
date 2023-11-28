# Create a placeholder
az containerapp job create -n "$PLACEHOLDER_JOB_NAME" -g "$RESOURCE_GROUP" --environment "$ENVIRONMENT" \
    --trigger-type Manual \
    --replica-timeout 300 \
    --replica-retry-limit 1 \
    --replica-completion-count 1 \
    --parallelism 1 \
    --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
    --cpu "2.0" \
    --memory "4Gi" \
    --secrets "personal-access-token=$AZP_TOKEN" "organization-url=$ORGANIZATION_URL" \
    --env-vars "AZP_TOKEN=secretref:personal-access-token" "AZP_URL=secretref:organization-url" "AZP_POOL=$AZP_POOL" "AZP_PLACEHOLDER=1" "AZP_AGENT_NAME=placeholder-agent" \
    --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" \
    --registry-password "$CONTAINER_REGISTRY_PASSWORD"

# Start the placeholder
az containerapp job start -n "$PLACEHOLDER_JOB_NAME" -g "$RESOURCE_GROUP"

# List executions
az containerapp job execution list \
    --name "$PLACEHOLDER_JOB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table \
    --query '[].{Status: properties.status, Name: name, StartTime: properties.startTime}'

# Create the real job
az containerapp job create -n "$JOB_NAME" -g "$RESOURCE_GROUP" --environment "$ENVIRONMENT" \
    --trigger-type Event \
    --replica-timeout 1800 \
    --replica-retry-limit 1 \
    --replica-completion-count 1 \
    --parallelism 1 \
    --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
    --min-executions 0 \
    --max-executions 10 \
    --polling-interval 30 \
    --scale-rule-name "azure-pipelines" \
    --scale-rule-type "azure-pipelines" \
    --scale-rule-metadata "poolName=container-apps" "targetPipelinesQueueLength=1" \
    --scale-rule-auth "personalAccessToken=personal-access-token" "organizationURL=organization-url" \
    --cpu "2.0" \
    --memory "4Gi" \
    --secrets "personal-access-token=$AZP_TOKEN" "organization-url=$ORGANIZATION_URL" \
    --env-vars "AZP_TOKEN=secretref:personal-access-token" "AZP_URL=secretref:organization-url" "AZP_POOL=$AZP_POOL" \
    --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io"