# MongoDB Backup and Upload to Azure Storage

This guide describes how to set up a scheduled task to dump a MongoDB database from a virtual machine (VM), compress it into a password-protected zip file, and upload it to an Azure Storage account using Managed Identities.

## Prerequisites

1. **Azure Virtual Machine** with MongoDB installed.
2. **Azure Storage Account** with a container.
3. **Managed Identity** enabled on the VM.
4. **Azure CLI** installed on the VM.
5. **MongoDB Tools** installed on the VM (e.g., `mongodump`).
6. **Zip utility** installed on the VM.

## Steps

1. **Enable Managed Identity on VM**
   - Enable the managed identity for your VM through the Azure portal or using Azure CLI.

2. **Grant Permissions to Managed Identity**
   - Grant the managed identity access to the storage account using Azure CLI.

3. **Install Required Tools**
   - Ensure `mongodump`, `zip`, and `azure-cli` are installed on your VM.

4. **Create Backup Script**
   - Create a script that dumps the MongoDB database, compresses it into a password-protected zip file, and uploads it to Azure Storage.

5. **Schedule the Backup Script**
   - Schedule the script using `cron` to run at your desired interval.

6. **Verify Backup**
   - Ensure the cron job is running as expected by checking the logs and verifying the presence of the backup files in your Azure Storage container.

## Conclusion

You have now set up a scheduled task to dump your MongoDB database, compress it into a password-protected zip file, and upload it to Azure Storage using Managed Identities. This ensures your database backups are securely stored and easily accessible.
