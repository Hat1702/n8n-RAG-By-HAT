#!/bin/sh
set -eu

alias_name="local"
endpoint="http://minio:9000"

until mc alias set "$alias_name" "$endpoint" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"; do
  sleep 2
done

mc mb --ignore-existing "$alias_name/$MINIO_DOCUMENTS_BUCKET"
mc anonymous set none "$alias_name/$MINIO_DOCUMENTS_BUCKET"
