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
echo "Postgres server connection information:"
az postgres server show \
    --resource-group $resourceGroup \
    --name $postgresqlServer
