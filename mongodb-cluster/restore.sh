#!/bin/bash

# --- Configuration for Download ---
OBJECT_STORAGE_URL="https://hel1.your-objectstorage.com"
BUCKET_NAME="v5-bucket"
ACCESS_KEY="QE662HNAHA7L5SO2NWDE"
SECRET_KEY="P3bdsDU1jRGo3yB9kg7aLmLTN3Z1yv1qWxPpYjra"
BACKUP_FILE_NAME="backup_idrakdb_20250418124232.zip" # Replace with the actual filename in your bucket
LOCAL_DOWNLOAD_PATH="/home/support/mongodbk8-clsuter/dump-data/${BACKUP_FILE_NAME}" # Adjust the local path

# --- Function to construct the S3 authorization header ---
construct_s3_auth_header() {
  local http_verb="$1"
  local content_type="$2"
  local date_value="$3"
  local canonicalized_resource="$4"
  local string_to_sign="${http_verb}\n\n${content_type}\n${date_value}\n${canonicalized_resource}"
  local signature=$(echo -en "$string_to_sign" | openssl sha1 -hmac "$SECRET_KEY" -binary | base64)
  echo "Authorization: AWS ${ACCESS_KEY}:${signature}"
}

# --- Download the backup file ---
DATE_VALUE=$(date -R)
CANONICALIZED_RESOURCE="/${BUCKET_NAME}/${BACKUP_FILE_NAME}"
AUTH_HEADER=$(construct_s3_auth_header "GET" "" "$DATE_VALUE" "$CANONICALIZED_RESOURCE")
BACKUP_URL="${OBJECT_STORAGE_URL}/${BUCKET_NAME}/${BACKUP_FILE_NAME}"

echo "$(date): Downloading ${BACKUP_URL} to ${LOCAL_DOWNLOAD_PATH}"
curl -v -X GET -o "${LOCAL_DOWNLOAD_PATH}" \
  -H "Date: ${DATE_VALUE}" \
  -H "${AUTH_HEADER}" \
  "${BACKUP_URL}"

if [ $? -eq 0 ]; then
  echo "$(date): Download completed successfully to ${LOCAL_DOWNLOAD_PATH}"
else
  echo "$(date): Error: Download failed."
fi

echo "$(date): Download process finished."
