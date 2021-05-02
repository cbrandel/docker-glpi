#!/bin/bash


echo "Create structure in ${GLPI_VAR_DIR} folder..."
for f in _cache _cron _dumps _graphs _lock _log _pictures _plugins _rss _sessions _tmp _uploads; do
  dir="${GLPI_VAR_DIR}/files/${f}"
  if [ ! -d "${dir}" ]; then
    mkdir -p "${dir}"
    chown www-data:www-data "${dir}"
    chmod u=rwX,g=rwX,o=--- "${dir}"
  fi
done

exec "$@"
