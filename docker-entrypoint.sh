#!/bin/bash

echo "Create structure in ${GLPI_VAR_DIR} folder..."
dirs=(
    "_cache"
    "_cron"
    "_dumps"
    "_graphs"
    "_lock"
    "_log"
    "_pictures"
    "_plugins"
    "_rss"
    "_sessions"
    "_tmp"
    "_uploads"
)
for dir in "${dirs[@]}"
do
    if [ ! -d "${GLPI_VAR_DIR}/${dir}" ]
    then
        mkdir "$dir"
    fi
done
chown -R www-data:www-data "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}"
chmod -R u=rwX,g=rwX,o=--- "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}"

echo "Create config_db.php file..."
(
cat <<EOF
<?php
class DB extends DBmysql {
   public \$dbhost     = 'glpi-db';
   public \$dbuser     = '$MYSQL_USER';
   public \$dbpassword = '$MYSQL_PASSWORD';
   public \$dbdefault  = '$MYSQL_DATABASE';
}
EOF
) > "${GLPI_CONFIG_DIR}/config_db.php"

# check for database
nok=10
echo -n "Waiting for glpi-db"
while [ $nok != 0 ]
do
    echo -n "."
    nc -w 30 -z glpi-db 3306
    if [ $? == 0 ]
    then
        break
    else
        nok=$(($nok - 1))
        sleep 5
    fi
done
echo
cd "${GLPI_ROOT}"
db_res=$(bin/console glpi:database:check > /dev/null 2>&1)
if [ $? == 255 ]
then
  echo "Database does not exist."
  bin/console glpi:database:install -n
fi
# run database update, just in case.
bin/console glpi:database:update -n

# delete the install file
test -f "${GLPI_ROOT}/install/install.php" && rm "${GLPI_ROOT}/install/install.php"

# re-set permissions, in case anything has changed
chown -R www-data:www-data "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}"
chmod -R u=rwX,g=rwX,o=--- "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}"

exec "$@"
