#!/bin/bash

service_name=bind9

set -e

echo `service ${service_name} status`
echo '1.启动${service_name}....'
service ${service_name} start
sleep 3
echo `service ${service_name} status`

tail -f /dev/null
