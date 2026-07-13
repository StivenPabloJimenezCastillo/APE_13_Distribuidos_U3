#!/bin/bash

echo "🔄 1. Limpiando contenedores y volúmenes previos..."
docker compose down -v

echo "🚀 2. Levantando la infraestructura (Maestro + 2 Réplicas)..."
docker compose up -d

echo "⏳ Esperando 5 segundos a que MariaDB inicialice completamente..."
sleep 5

echo "👤 3. Creando usuario de replicación en el Maestro..."
docker exec -it mdb-master mariadb -u root -prootpass -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'replpass'; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'; FLUSH PRIVILEGES;"

echo "🔍 4. Obteniendo estado del log maestro de forma automática..."
# Extraemos el archivo binario y la posición usando awk
MASTER_STATUS=$(docker exec -i mdb-master mariadb -u root -prootpass -e "SHOW MASTER STATUS;")
LOG_FILE=$(echo "$MASTER_STATUS" | awk 'NR==2 {print $1}')
LOG_POS=$(echo "$MASTER_STATUS" | awk 'NR==2 {print $2}')

echo "   -> Archivo detectado: $LOG_FILE"
echo "   -> Posición detectada: $LOG_POS"

echo "⛓️ 5. Configurando la Réplica 1..."
docker exec -it mdb-replica1 mariadb -u root -prootpass -e "CHANGE MASTER TO MASTER_HOST='mdb-master', MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS; START SLAVE;"

echo "⛓️ 6. Configurando la Réplica 2..."
docker exec -it mdb-replica2 mariadb -u root -prootpass -e "CHANGE MASTER TO MASTER_HOST='mdb-master', MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS; START SLAVE;"

echo "✅ 7. Verificando el estado final de las conexiones..."
echo "----------------------------------------"
echo "Estado Réplica 1:"
docker exec -i mdb-replica1 mariadb -u root -prootpass -e "SHOW SLAVE STATUS\G" | grep _Running
echo "----------------------------------------"
echo "Estado Réplica 2:"
docker exec -i mdb-replica2 mariadb -u root -prootpass -e "SHOW SLAVE STATUS\G" | grep _Running
echo "----------------------------------------"

echo "¡Todo listo! Ya puedes ir a DBeaver a crear tu base de datos y probar."
