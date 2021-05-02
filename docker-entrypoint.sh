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
chown www-data:www-data "${GLPI_VAR_DIR}"
chmod u=rwX,g=rwX,o=--- "${GLPI_VAR_DIR}"

echo "Create config_db.php file..."
(
cat <<EOF
<?php
class DB extends DBmysql {
   public \$dbhost     = 'mariadb';
   public \$dbuser     = '$MYSQL_USER';
   public \$dbpassword = '$MYSQL_PASSWORD';
   public \$dbdefault  = '$MYSQL_DATABASE';
}
EOF
) > "${GLPI_CONFIG_DIR}/config_db.php"

# check for database
cd "${GLPI_ROOT}"
db_res=$(bin/console glpi:database:check > /dev/null 2>&1)
if [ $? == 255 ]
then
  echo "Database does not exist."
  bin/console glpi:database:install -n > /dev/null 2>&1
fi
# run database update, just in case.
bin/console glpi:database:install -n > /dev/null 2>&1

# delete the install file
test -f "${GLPI_ROOT}/install/install.php" && rm "${GLPI_ROOT}/install/install.php"

exec "$@"
