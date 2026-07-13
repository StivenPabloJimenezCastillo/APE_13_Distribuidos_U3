Simular caida del nodo maestro
docker stop mdb-master

# Detener la replicación y limpiar la configuración de esclavo
docker exec -it mdb-replica1 mariadb -u root -prootpass -e "STOP SLAVE; RESET SLAVE ALL;"

#Probar la escritura en el Nuevo Maestro (Réplica 1)
docker exec -it mdb-replica1 mariadb -u root -prootpass -e "USE control_usuarios; INSERT INTO personas (nombre, apellido) VALUES ('Failover', 'Exitoso');"

#Verificar que se guardó correctamente en ella, haz el SELECT:
docker exec -it mdb-replica1 mariadb -u root -prootpass -e "USE control_usuarios; SELECT * FROM personas;"

#Consultar la replicación en la réplica 2
docker exec -it mdb-replica2 mariadb -u root -prootpass -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Last_IO_Error"
