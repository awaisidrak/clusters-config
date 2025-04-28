#!/bin/bash
# backup_mongodb_zip.sh: Backup a MongoDB to a ZIP file and upload to object storage

# --- Configuration ---
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="/var/backups/mongodb"
MONGODB_URI="mongodb://idrakuser:123idrak123@65.21.159.98:31017,95.217.187.105:31018,157.180.31.13:31019/idrakdb?authSource=admin&replicaSet=rs0"
MONGODB_DATABASE="idrakdb"
AUTH_SOURCE="admin"

OBJECT_STORAGE_URL="https://hel1.your-objectstorage.com"
BUCKET_NAME="v5-bucket"
ACCESS_KEY="QE662HNAHA7L5SO2NWDE"
SECRET_KEY="P3bdsDU1jRGo3yB9kg7aLmLTN3Z1yv1qWxPpYjra"

# Define content type for the upload (adjust as needed)
CONTENT_TYPE="application/zip"

mkdir -p "$BACKUP_DIR"

# --- Define backup file name ---
BACKUP_FILE="${BACKUP_DIR}/backup_${MONGODB_DATABASE}_${TIMESTAMP}.zip"
TEMP_DUMP_DIR="${BACKUP_DIR}/temp_dump_${TIMESTAMP}"

# --- Dump the database to a directory ---
mkdir -p "$TEMP_DUMP_DIR"

mongodump --uri="$MONGODB_URI" --db "$MONGODB_DATABASE" --out "$TEMP_DUMP_DIR"

if [ $? -eq 0 ]; then
    echo "$(date): Dump succeeded to: $TEMP_DUMP_DIR"

    # --- Create a ZIP archive with relative path ---
    cd "$BACKUP_DIR"
    zip -r "$(basename "$BACKUP_FILE")" "$(basename "$TEMP_DUMP_DIR")"
    cd -

    if [ $? -eq 0 ]; then
        echo "$(date): ZIP archive created: $BACKUP_FILE"

        DATE_VALUE=$(date -R)

        # Construct the canonicalized resource string: /bucket-name/object-name
        OBJECT_NAME=$(basename "$BACKUP_FILE")
        CANONICALIZED_RESOURCE="/${BUCKET_NAME}/${OBJECT_NAME}"

        # Format: HTTP-VERB + "\n" + Content-MD5 + "\n" + Content-Type + "\n" + Date + "\n" + CanonicalizedResource
        # We assume an empty Content-MD5.
        STRING_TO_SIGN="PUT\n\n${CONTENT_TYPE}\n${DATE_VALUE}\n${CANONICALIZED_RESOURCE}"

        # Compute the signature using HMAC-SHA1 and Base64 encode it
        SIGNATURE=$(echo -en "$STRING_TO_SIGN" | openssl sha1 -hmac "$SECRET_KEY" -binary | base64)

        # Construct the Authorization header in the format expected by S3
        AUTH_HEADER="Authorization: AWS ${ACCESS_KEY}:${SIGNATURE}"

        # The full URL for the object will be: OBJECT_STORAGE_URL/bucket-name/object-name
        FULL_URL="${OBJECT_STORAGE_URL}/${BUCKET_NAME}/${OBJECT_NAME}"

        echo "Uploading to: ${FULL_URL}"

        curl -v -X PUT -T "$BACKUP_FILE" \
            -H "Content-Type: ${CONTENT_TYPE}" \
            -H "Date: ${DATE_VALUE}" \
            -H "${AUTH_HEADER}" \
            "${FULL_URL}"

        if [ $? -eq 0 ]; then
            echo "$(date): Upload succeeded."

            # Unzip and list content.
            UNZIP_DIR="${BACKUP_DIR}/unzipped_${TIMESTAMP}"
            mkdir -p "$UNZIP_DIR"
            unzip -d "$UNZIP_DIR" "$BACKUP_FILE"

            if [ $? -eq 0 ]; then
                echo "$(date): Unzipped to $UNZIP_DIR"
                echo "$(date): Contents of unzipped directory:"
                ls -l "$UNZIP_DIR"
            else
                echo "$(date): Unzip failed." >&2
            fi

        else
            echo "$(date): Upload failed." >&2
        fi

        # Clean up the temp directory
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
