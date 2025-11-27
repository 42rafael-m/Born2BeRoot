#!/bin/bash

# 1. Arquitectura del SO y versión del Kernel
arch=$(uname -a)

# 2. Número de núcleos físicos (CPUs físicas)
# Busca líneas con "physical id" en cpuinfo. Si no hay (VM simple), cuenta sockets.
cpuf=$(grep "physical id" /proc/cpuinfo | wc -l)

# 3. Número de núcleos virtuales (vCPUs)
# Cuenta las veces que aparece "processor"
cpuv=$(grep "processor" /proc/cpuinfo | wc -l)

# 4. Memoria RAM (Usada / Total y Porcentaje)
# Usa 'free -m' y awk para calcular y formatear
ram_total=$(free -m | awk '$1 == "Mem:" {print $2}')
ram_use=$(free -m | awk '$1 == "Mem:" {print $3}')
ram_percent=$(free | awk '$1 == "Mem:" {printf("%.2f"), $3/$2*100}')

# 5. Uso de Disco (Usado / Total y Porcentaje)
# Suma el espacio de todos los discos que empiezan por /dev/, excluyendo /boot
disk_total=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_t += $2} END {printf ("%.0fGb"), disk_t/1024}')
disk_use=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_u += $3} END {print disk_u}')
disk_percent=$(df -m | grep "/dev/" | grep -v "/boot" | awk '{disk_u += $3} {disk_t += $2} END {printf("%d"), disk_u/disk_t*100}')

# 6. Carga de CPU (CPU Load)
# Usa top en modo batch (-b) una vez (-n1) y extrae la carga del sistema+usuario
cpu_load=$(top -bn1 | grep "^%Cpu" | cut -c 9- | xargs | awk '{printf("%.1f%%"), $1 + $3}')

# 7. Fecha y hora del último reinicio
lb=$(who -b | awk '{print $3 " " $4}')

# 8. ¿LVM activo?
# Si lsblk encuentra líneas con "lvm", es que está activo.
lvm_use=$(if [ $(lsblk | grep "lvm" | wc -l) -gt 0 ]; then echo yes; else echo no; fi)

# 9. Conexiones TCP activas
# Usa 'ss' (sucesor de netstat) para contar conexiones ESTABLISHED
tcpc=$(ss -ta | grep ESTAB | wc -l)

# 10. Número de usuarios logueados
ulog=$(users | wc -w)

# 11. Dirección IP y MAC
# hostname -I da la IP. ip link busca la MAC de la interfaz ethernet.
ip=$(hostname -I)
mac=$(ip link | grep "link/ether" | awk '{print $2}')

# 12. Número de comandos ejecutados con Sudo
# Busca en los logs del sistema (journalctl) las entradas del comando sudo
cmnd=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

# --- SALIDA AL MURO (WALL) ---
# Se envía el mensaje a todos los terminales
wall "
    #Architecture: $arch
    #CPU physical : $cpuf
    #vCPU : $cpuv
    #Memory Usage: $ram_use/${ram_total}MB ($ram_percent%)
    #Disk Usage: $disk_use/${disk_total} ($disk_percent%)
    #CPU load: $cpu_load
    #Last boot: $lb
    #LVM use: $lvm_use
    #Connections TCP : $tcpc ESTABLISHED
    #User log: $ulog
    #Network: IP $ip ($mac)
    #Sudo : $cmnd cmd"
