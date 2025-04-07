#!/bin/bash
# backup_mongodb_zip.sh: Backup a MongoDB to a ZIP file and upload to object storage

# --- Configuration ---
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="/var/backups/mongodb"
MONGODB_URI="mongodb://idrakuser:123idrak123@49.13.83.180:27017,49.13.89.133:27018,138.199.152.36:27019/idrakdb?replicaSet=myReplicaSet&readPreference=secondaryPreferred&w=1&authSource=admin"
MONGODB_DATABASE="idrakdb"
AUTH_SOURCE="admin"

OBJECT_STORAGE_URL="https://fsn1.your-objectstorage.com"
BUCKET_NAME="v8bucket"
ACCESS_KEY="1GV0NSNQG9JCJ3AUIL8Q"
SECRET_KEY="pxQ32JHm6AxDTkID4u1P2BAVpY6FUK8MHXfGBXHR"

CONTENT_TYPE="application/zip"

mkdir -p "$BACKUP_DIR"

BACKUP_FILE="${BACKUP_DIR}/backup_${MONGODB_DATABASE}_${TIMESTAMP}.zip"
TEMP_DUMP_DIR="${BACKUP_DIR}/temp_dump_${TIMESTAMP}"

mkdir -p "$TEMP_DUMP_DIR"

# --- Dump MongoDB ---
mongodump --uri="$MONGODB_URI" --db "$MONGODB_DATABASE" --out "$TEMP_DUMP_DIR"

if [ $? -eq 0 ]; then
    echo "$(date): Dump succeeded to: $TEMP_DUMP_DIR"

    # --- Create ZIP archive with relative path ---
    cd "$BACKUP_DIR"
    zip -r "$(basename "$BACKUP_FILE")" "$(basename "$TEMP_DUMP_DIR")"
    ZIP_EXIT=$?
    cd -

    if [ $ZIP_EXIT -eq 0 ]; then
        echo "$(date): ZIP archive created: $BACKUP_FILE"

        DATE_VALUE=$(date -R)
        OBJECT_NAME=$(basename "$BACKUP_FILE")
        CANONICALIZED_RESOURCE="/${BUCKET_NAME}/${OBJECT_NAME}"
        STRING_TO_SIGN="PUT\n\n${CONTENT_TYPE}\n${DATE_VALUE}\n${CANONICALIZED_RESOURCE}"

        # --- Generate AWS Signature Version 2 using HMAC-SHA1 ---
        SIGNATURE=$(echo -en "$STRING_TO_SIGN" | openssl dgst -sha1 -hmac "$SECRET_KEY" -binary | base64)
        AUTH_HEADER="Authorization: AWS ${ACCESS_KEY}:${SIGNATURE}"
        FULL_URL="${OBJECT_STORAGE_URL}/${BUCKET_NAME}/${OBJECT_NAME}"

        echo "Uploading to: ${FULL_URL}"

        # --- Perform upload with HTTP response capture ---
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -T "$BACKUP_FILE" \
            -H "Content-Type: ${CONTENT_TYPE}" \
            -H "Date: ${DATE_VALUE}" \
            -H "${AUTH_HEADER}" \
            "${FULL_URL}")

        if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "$(date): Upload succeeded."

            # --- Unzip for verification ---
            UNZIP_DIR="${BACKUP_DIR}/unzipped_${TIMESTAMP}"
            mkdir -p "$UNZIP_DIR"
            unzip -d "$UNZIP_DIR" "$BACKUP_FILE"

            if [ $? -eq 0 ]; then
                echo "$(date): Unzipped to $UNZIP_DIR"
                echo "$(date): Contents of unzipped directory:"
                ls -l "$UNZIP_DIR/$(basename "$TEMP_DUMP_DIR")"
            else
                echo "$(date): Unzip failed." >&2
            fi
        else
            echo "$(date): Upload failed with HTTP status: $HTTP_STATUS" >&2
        fi

        # --- Cleanup ---
        rm -rf "$TEMP_DUMP_DIR"
    else
        echo "$(date): ZIP creation failed." >&2
        rm -rf "$TEMP_DUMP_DIR"
        exit 1
    fi
else
    echo "$(date): Dump failed." >&2
    exit 1
fi
