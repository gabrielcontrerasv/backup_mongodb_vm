#!/bin/bash

BACKUP_DIR="/mongodb_backup"
ZIP_PASSWORD="trackmile123**"
STORAGE_ACCOUNT_NAME="inteiascdevtrackmile"
CONTAINER_NAME="database-backups"


sudo mkdir -p $BACKUP_DIR/{scripts,backups,logs}


sudo apt update
sudo apt install -y python3-pip zip mongodb-org-tools
sudo pip3 install azure-identity azure-storage-blob


sudo tee /etc/profile.d/mongodb_backup_env.sh > /dev/null <<EOT
export MONGO_BACKUP_USER="backupUser"
export MONGO_BACKUP_PASSWORD="trackmile"
export MONGO_HOST="localhost"
export MONGO_PORT="27017"
export MONGO_AUTH_DB="admin"
EOT
sudo chmod 600 /etc/profile.d/mongodb_backup_env.sh



cat << EOF | sudo tee $BACKUP_DIR/scripts/backup_and_upload.sh
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR/backups"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mongodb_backup_\$TIMESTAMP"
ZIP_PASSWORD="$ZIP_PASSWORD"
STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME"
CONTAINER_NAME="$CONTAINER_NAME"

# Cargar variables de entorno de MongoDB
source /etc/profile.d/mongodb_backup_env.sh

echo "Iniciando proceso de backup: \$(date)"

# Generar backup
echo "Generando backup de MongoDB..."
mongodump --host \$MONGO_HOST --port \$MONGO_PORT --username \$MONGO_BACKUP_USER --password \$MONGO_BACKUP_PASSWORD --authenticationDatabase \$MONGO_AUTH_DB --out \$BACKUP_DIR/\$BACKUP_NAME

# Verificar si el dump fue exitoso
if [ \$? -ne 0 ]; then
    echo "Error al generar el backup de MongoDB. Abortando el proceso."
    exit 1
fi

# Comprimir backup
echo "Comprimiendo backup..."
zip -r -P \$ZIP_PASSWORD \$BACKUP_DIR/\${BACKUP_NAME}.zip \$BACKUP_DIR/\$BACKUP_NAME
rm -rf \$BACKUP_DIR/\$BACKUP_NAME

# Subir a Azure
echo "Subiendo backup a Azure..."
python3 $BACKUP_DIR/scripts/upload_to_azure.py \$BACKUP_DIR/\${BACKUP_NAME}.zip \$STORAGE_ACCOUNT_NAME \$CONTAINER_NAME

if [ \$? -eq 0 ]; then
    echo "Backup subido exitosamente. Eliminando archivo local."
    rm \$BACKUP_DIR/\${BACKUP_NAME}.zip
else
    echo "Error al subir el backup. El archivo local se mantendrá."
fi

# Limpiar backups antiguos
echo "Limpiando backups antiguos..."
find \$BACKUP_DIR -name "mongodb_backup_*" -type f -mtime +7 -delete

echo "Proceso de backup completado: \$(date)"
EOF



cat << EOF | sudo tee $BACKUP_DIR/scripts/upload_to_azure.py
import sys
import os
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient

def upload_to_azure(file_path, storage_account_name, container_name):
    try:
        credential = ManagedIdentityCredential()
        account_url = f"https://{storage_account_name}.blob.core.windows.net"
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)
        container_client = blob_service_client.get_container_client(container_name)
        blob_name = os.path.basename(file_path)
        with open(file_path, "rb") as data:
            container_client.upload_blob(name=blob_name, data=data, overwrite=True)
        print(f"Archivo {blob_name} subido exitosamente a {container_name}.")
        return 0
    except Exception as e:
        print(f"Error al subir el archivo: {str(e)}")
        return 1

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Uso: python upload_to_azure.py <ruta_archivo> <nombre_cuenta_almacenamiento> <nombre_contenedor>")
        sys.exit(1)
    sys.exit(upload_to_azure(sys.argv[1], sys.argv[2], sys.argv[3]))
EOF




sudo chown -R root:root $BACKUP_DIR
sudo chmod -R 755 $BACKUP_DIR
sudo chmod 700 $BACKUP_DIR/scripts/*.sh
sudo chmod 700 $BACKUP_DIR/scripts/*.py




(crontab -l 2>/dev/null; echo "* * * * * $BACKUP_DIR/scripts/backup_and_upload.sh >> $BACKUP_DIR/logs/backup.log 2>&1") | sudo crontab -

echo "Configuración completada. El proceso de backup y carga se ejecutará cada minuto (con fines didácticos)."