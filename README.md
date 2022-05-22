# TechConf Registration Website

## Project Overview

The TechConf website allows attendees to register for an upcoming conference. Administrators can also view the list of attendees and notify all attendees via a personalized email message.

The application is currently working but the following pain points have triggered the need for migration to Azure:

- The web application is not scalable to handle user load at peak
- When the admin sends out notifications, it's currently taking a long time because it's looping through all attendees, resulting in some HTTP timeout exceptions
- The current architecture is not cost-effective

In this project, you worked on the following:

- Migrate and deploy the pre-existing web app to an Azure App Service
- Migrate a PostgreSQL database backup to an Azure Postgres database instance
- Refactor the notification logic to an Azure Function via a service bus queue message

Below are the project steps I have taken to complete the project.

## Dependencies
You will need to install the following locally:

- [Postgres](https://www.postgresql.org/download/)
- [Visual Studio Code](https://code.visualstudio.com/download)
- [Azure Function tools V3](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash#install-the-azure-functions-core-tools)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure Tools for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)

## Project Instructions

### Part 1: Create Azure Resources and Deploy Web App

1. Create a **Resource group**
2. Create an **Azure Postgres Database** flexible server
    - Allow all IPs to connect to database server
    - Add a new database `techconfdb`
        - First connect locally to your server. You can use `psql` or pgAdmin, which are popular PostgreSQL clients. For this project, we'll connect by using `psql` in our local bash shell. Run the following command in your terminal:
            ```bash
            psql "host=$postgresqlServer.postgres.database.azure.com port=5432 dbname=postgres user=$adminLogin password=$adminPassword sslmode=require"
            ```
        - List all databases created by default by typing `\l`
        - In the same terminal, create a new database called techconfdb:
            ```bash
            CREATE DATABASE techconfdb;
            ```
    - To migrate the local database to Azure, restore the database with the backup located in the [data](data) folder:
        ```bash
        PGPASSWORD=$adminPassword psql --file=data/techconfdb_backup.sql --host=$postgresqlServer.postgres.database.azure.com --port=5432 --dbname=techconfdb --username=$adminLogin
        ```
        - Validate that the database was migrated by typing the following:
            ```bash
            psql "host=$postgresqlServer.postgres.database.azure.com port=5432 dbname=postgres user=$adminLogin password=$adminPassword sslmode=require"
            \c techconfdb
            \dt
            SELECT * FROM attendee;
            SELECT * FROM conference;
            SELECT * FROM notification;
            ```
            You should see the database populated with data in each table. For example this shows the conference table with all data:
            ```bash
            techconfdb=> SELECT * FROM conference;
             id |   name   | active |    date    | price |             address              
            ----+----------+--------+------------+-------+----------------------------------
              1 | TechConf | 1      | 2022-06-10 |   495 | 123 Main St, Baltimore, MD 12345
              2 | TestConf | 0      | 1999-01-01 |     1 | 9
            ```
3. Create a **Service Bus** resource with a `notificationqueue` that will be used to communicate between the web and the function
    - Open the [web](web) folder and update the following in the `config.py` file
        - `POSTGRES_URL`
        - `POSTGRES_USER`
        - `POSTGRES_PW`
        - `POSTGRES_DB`
        - `SERVICE_BUS_CONNECTION_STRING`
4. Create App Service plan
5. Create a storage account
6. Deploy the web app

