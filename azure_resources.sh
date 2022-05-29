# Variables for Azure resources
let "randomIdentifier=$RANDOM*$RANDOM"
resourceGroup="registration-app-rg-$randomIdentifier"
location="westeurope"
# serverTag="postgresql-server-with-firewall-rule"
postgresqlServer="postgresql-server-$randomIdentifier"
# The name of the compute SKU for postgresql server
sku="Standard_B1ms"
# Postgresql server admin username
adminLogin="<enter-your-admin-username-here>"
# Password for the server admin user
adminPassword="<enter-your-admin-password-here>"
# Specify appropriate IP address values for your environment to limit/allow access 
# to the PostgreSQL server -> Here we allow all IPs to connect to database server
startIp=0.0.0.0
endIp=255.255.255.255
# Service Bus namespace
serviceBusNamespace="techconf-service-bus-namespace"
# Service Bus Queue name
serviceBusQueue="notificationqueue"
# Storage account unique name
storageAccount="storageaccount$randomIdentifier"
# App Service Plan name
appServicePlanName="appserviceplan$randomIdentifier"
# Web App name
webAppName="registration-app-$randomIdentifier"
# Function App name
functionAppName="function-app-$randomIdentifier"


# Create a resource group
echo "Creating resource group $resourceGroup in $location..."
az group create --name $resourceGroup --location $location

# Create a PostgreSQL flexible server in the resource group
echo "Creating a PostgreSQL flexible server $postgresqlServer in $location..."
az postgres flexible-server create \
    --name $postgresqlServer \
    --resource-group $resourceGroup \
    --location "$location" \
    --admin-user $adminLogin \
    --admin-password $adminPassword \
    --tier Burstable \
    --sku-name $sku \
    --storage-size 32 \
    --version 12

# Configure a firewall rule for the server 
echo "Configuring a firewall rule for $postgresqlServer for the IP address range of $startIp to $endIp"
az postgres flexible-server firewall-rule create \
    --resource-group $resourceGroup \
    --name $postgresqlServer \
    --rule-name AllowAllIps \
    --start-ip-address $startIp \
    --end-ip-address $endIp

# List firewall rules for the server
echo "List of server-based firewall rules for $postgresqlServer"
az postgres flexible-server firewall-rule list \
    --resource-group $resourceGroup \
    --name $postgresqlServer \
    --output table

# Get the connection information to connect to your server (it provides host 
# information and access credentials
echo "Postgres server connection information..."
az postgres server show \
    --resource-group $resourceGroup \
    --name $postgresqlServer

# Create a Service Bus Namespace
echo "Creating a Service Bus Namespace..."
az servicebus namespace create \
    --name $serviceBusNamespace \
    --resource-group $resourceGroup \
    --location $location \
    --sku Basic

# Create a Service Bus Queue in the Service Bus Namespace
echo "Creating a Service Bus Queue in the Service Bus Namespace..."
az servicebus queue create \
    --name $serviceBusQueue \
    --namespace-name $serviceBusNamespace \
    --resource-group $resourceGroup

# List the primary connection string for the Service Bus Namespace
echo "List the primary connection string for the Service Bus Namespace:"

az servicebus namespace authorization-rule keys list \
    --name RootManageSharedAccessKey \
    --namespace-name $serviceBusNamespace \
    --resource-group $resourceGroup \
    --query primaryConnectionString \
    --output table

# Create a storage account
echo "Creating a storage account..."
az storage account create \
    --name $storageAccount \
    --resource-group $resourceGroup \
    --location $location

# Create App Service plan and deploy the webapp 
az webapp up \
    --resource-group $resourceGroup \
    --name $webAppName \
    --plan $appServicePlanName \
    --sku F1 \
    --verbose


# Creates a new Functions project in a specific language.
func init --worker-runtime python

# Create an Azure Function in the function folder that is triggered by the service bus queue 
func new \
    --name ServiceBusQueueTrigger \
    --template "Azure Service Bus Queue trigger"

# Create a function app on Azure
az functionapp create \
    --name $functionAppName \
    --resource-group $resourceGroup \
    --storage-account $storageAccount \
    --functions-version 4 \
    --os-type Linux \
    --runtime python \
    --runtime-version 3.8 \
    --consumption-plan-location $location

# Deploy a Functions project to an existing function app resource in Azure
func azure functionapp publish $functionAppName --publish-local-settings -i
