# !/bin/bash

pod="$1"

case $pod in 
	e1)
	 urlq="https://site1.dev" ; Regions='e1.sh e2.sh e3.sh e4.sh' ; portal_token=`cat tokens/token_portal.txt` ; urls='https://site1.dev' ;;
	e2)
	 urlq="https://site2.ru" ; Regions='w1.sh w2.sh w3.sh w4.sh' ; portal_token=`cat tokens/token_portal2.txt` ; urls='https://site2.ru' ;;
	e3)
	 urlq="https://site3.ru" ; Regions='r1.sh r2.sh r3.sh' ; portal_token=`cat tokens/token_portal3.txt` ; urls='https://site3.ru' ;;
 	e4)
	 urlq="https://site4.ru" ; Regions='d1.sh d2.sh d3.sh' ; portal_token=`cat tokens/token_portal4.txt` ; urls='https://site4.ru' ;;
 	e5)
	 urlq="https://site5.ru" ; Regions='v1.sh v2.sh v3.sh' ; portal_token=`cat tokens/token_portal5.txt` ; urls='https://site5.ru' ;;
esac

vm_name="$2"

#Поиск ВМ по регионам

for each in $Regions; 
do
	source ./$each > /dev/null 2>&1

	if [[ `echo $vm_name | wc -c` = '37' ]]; then
		uuid_vm=`curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" \
			$OS__EP_URL_COMPUTE/servers/$vm_name | \
				jq -r .server.id`
		if [[ `echo $uuid_vm | wc -c` != '37' ]]; then
			uuid_vm1=`curl --silent -k -X GET -H 'Accept: application/json' \
				-H "Authorization: Bearer $portal_token" $urls/api/v1/servers/$vm_name \
				| jq -r '.server.region , .server.outputs.vm_id'`
			uuid_vm=`echo $uuid_vm1 | awk '{print $2;}'`
			reg=`echo $uuid_vm1 | awk '{print $1;}'`
			
			case $reg in
				kvm1)
					source ./e1.sh > /dev/null 2>&1 ; each='e1.sh' ;;
				kmnt1)
					source ./e2.sh > /dev/null 2>&1 ; each='e2.sh' ;;
				vm3)
					source ./e3.sh > /dev/null 2>&1 ; each='e3.sh' ;;
				vm4)
					source ./e4.sh > /dev/null 2>&1 ; each='e4.sh' ;;
				vm1)
					source ./w1.sh > /dev/null 2>&1 ; each='w1.sh' ;;
				vm2)
					source ./w2.sh > /dev/null 2>&1 ; each='w2.sh' ;;
				vm3)
					source ./w3.sh > /dev/null 2>&1 ; each='w3.sh' ;;
				M2)
					source ./w4.sh > /dev/null 2>&1 ; each='w4.sh' ;;
        SI)
          source ./r1.sh > /dev/null 2>&1 ; each='r1.sh' ;;
        T)
          source ./r2.sh > /dev/null 2>&1 ; each='r2.sh' ;;
        M)
          source ./r3.sh > /dev/null 2>&1 ; each='r3.sh' ;;
        I)
          source ./d1.sh > /dev/null 2>&1 ; each='d1.sh' ;;
        2NT)
          source ./d2.sh > /dev/null 2>&1 ; each='d2.sh' ;;
        ROM)
          source ./d3.sh > /dev/null 2>&1 ; each='d3.sh' ;;
        OM)
          source ./v3.sh > /dev/null 2>&1 ; each='v3.sh' ;;
			esac
		fi
	else
		uuid_vm=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
			$OS__EP_URL_COMPUTE/servers?name=$vm_name"&"all_tenants | \
				jq -r .servers[].id`
	fi

	if [[ `echo $uuid_vm | wc -c` = '37' ]]; then
		echo 'ВМ найдена на стойке' $each
		echo '#############################################################'
		break
	fi
done

if [[ `echo $uuid_vm | wc -c` != '37' ]]; then
	exit 0
fi

### Проверка пинга и доступности по ssh 22 и 9022
ips=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_NETWORK/v2.0/ports?device_id=$uuid_vm | \
	jq -r .ports[].fixed_ips[].ip_address`
net_id=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_NETWORK/v2.0/ports?device_id=$uuid_vm | \
	jq '.ports[0] | .network_id' | sed 's/\"//g'`

case $each in
	e1.sh)
	 rnet='1.1.1.1'
	 ;;
	e2.sh)
	 rnet='1.1.1.1'
	 ;;
	e3.sh)
	 rnet='1.1.1.1'
	 ;;
	e4.sh)
	 rnet='1.1.1.1'
	 ;;
	w1.sh)
	 rnet='1.1.1.1'
	 ;;
	w2.sh)
	 rnet='1.1.1.1'
	 ;;
	w3.sh)
	 rnet='1.1.1.1'
	 ;;
 	w4.sh)
	 rnet='1.1.1.1'
	 ;;
	r1.sh)
	 rnet='1.1.1.1'
	 ;;
	r2.sh)
	 rnet='1.1.1.1'
	 ;;
	r3.sh)
	 rnet='1.1.1.1'
	 ;;
	c1.sh)
	 rnet='1.1.1.1'
	 ;;
	c2.sh)
	 rnet='1.1.1.1'
	 ;;
	c3.sh)
	 rnet='1.1.1.1'
	 ;;
 	v3.sh)
	 rnet='1.1.1.1'
	 ;;
esac

for each_ip in $ips;
do
	sudo ssh -i ~/.ssh/1234 $rnet "sudo ip netns exec qdhcp-$net_id ping -c 2 -W 2 $each_ip"
	echo '-------------------------------------------------------------'
	echo 'Проверка порта 22 через - '$each_ip
        `sudo ssh -i ~/.ssh/1234 $rnet "sudo ip netns exec qdhcp-$net_id ssh -o BatchMode=yes \
		-o StrictHostKeyChecking=yes -o ConnectTimeout=2 $each_ip -p 22 'exit 0'" &> check_port.tmp`
	if [[ -n `cat check_port.tmp | grep 'timed out'` || -n `cat check_port.tmp | grep 'refused'` ]]; then
		echo "Порт False: `cat check_port.tmp | grep -E -o "timed out|refused"`"
	else
		echo "Порт True"
	fi
	echo 'Проверка порта 9022 через - '$each_ip
	`sudo ssh -i ~/.ssh/1234 $rnet "sudo ip netns exec qdhcp-$net_id ssh -o BatchMode=yes \
		-o StrictHostKeyChecking=yes -o ConnectTimeout=2 $each_ip -p 9022 'exit 0'" &> check_port.tmp`
	if [[ -n `cat check_port.tmp | grep 'timed out'` || -n `cat check_port.tmp | grep 'refused'` ]]; then
		echo "Порт False: `cat check_port.tmp | grep -E -o "timed out|refused"`"
	else
		echo "Порт True"
	fi
	rm check_port.tmp
	echo '-------------------------------------------------------------'
done

# Краткая основная информация по ВМ
echo '#############################################################'
curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_COMPUTE/servers/$uuid_vm | \
	jq -r '.server | "Имя VM: \(.name) \nСтатус: \(.status) \nUUID VM: \(.id) \nUUID Проекта: \(.metadata.project_name) \nДата создания: \(.created)"'
uuid_proj=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_COMPUTE/servers/$uuid_vm | jq -r '.server.metadata.project_name'`
echo '#############################################################'
echo "Информация по дискам:"
id_project=`curl --silent -k -X GET $OS_AUTH_URL/v3/projects?name=admin \
	-H "X-Auth-Token: $SYS_TOKEN" | jq -r '.projects[].id'`
uuid_disks=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_COMPUTE/servers/$uuid_vm/os-volume_attachments | jq -r '.volumeAttachments[].volumeId'`

for each in $uuid_disks;
do
	curl --silent -k -X GET $OS__EP_URL_CINDERV3/$id_project/volumes/$each \
		-H "X-Auth-Token: $SYS_TOKEN" | jq -r '.volume | "UUID Диска: \(.id) \nРазмер: \(.size) \nСтатус \(.status) \nПримонтирован: \(.attachments[].device) \nПрава: \(.metadata.attached_mode) \nЗагрузочный: \(.bootable) \nСтатус миграции: \(.migration_status) \nID_Теннанта: \(."os-vol-tenant-attr:tenant_id") \nХост диска: \(."os-vol-host-attr:host")"'
	echo '------'
done

echo '#############################################################'
curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_COMPUTE/servers/$uuid_vm | \
	jq -r '.server | "Гипервизор: \(."OS-EXT-SRV-ATTR:hypervisor_hostname") \nИмя ВМ на гипере: \(."OS-EXT-SRV-ATTR:instance_name")"'
numhyp=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_COMPUTE/servers/$uuid_vm | \
	        jq -r '.server | "\(."OS-EXT-SRV-ATTR:hypervisor_hostname")"'`
id_hyp=`curl --silent -k -X GET $OS__EP_URL_COMPUTE/os-hypervisors/$numhyp/search \
	-H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r .hypervisors[].id`
curl --silent -k -X GET $OS__EP_URL_COMPUTE/os-hypervisors/$id_hyp/uptime -H "Accept: application/json" \
	-H "X-Auth-Token: $SYS_TOKEN" | jq -r '.hypervisor | "Статус NOVA: \(.state) \nСостояние: \(.status) \nUptime: \(.uptime)"'
hypname=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	        $OS__EP_URL_COMPUTE/servers/$uuid_vm | \
		        jq -r '.server | "\(."OS-EXT-SRV-ATTR:instance_name")"'`
uuid_vm_portal=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_COMPUTE/servers/$uuid_vm | jq -r '.server.metadata.server_uuid'`
iphyp=`curl --silent -k -X GET $OS__EP_URL_COMPUTE/os-hypervisors/detail \
	-H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" \
	| jq -r '.hypervisors[] | "\(.hypervisor_hostname) \(.host_ip)"' | grep $numhyp | awk {'print $2'}`
echo "IP гипервизора: ssh -i .ssh/1234 "$iphyp
echo '#############################################################'
echo "Информация по сети:"
curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" \
	$OS__EP_URL_NETWORK/v2.0/ports?device_id=$uuid_vm | \
	jq -r '.ports[] | "Статус: \(.status) \nUUID Сети: \(.network_id) \nIP: \(.fixed_ips[].ip_address) \nVIF_Type: \(."binding:vif_type")"'
port_id=`curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_NETWORK/v2.0/ports?device_id=$uuid_vm | jq -r .ports[].id`
echo "ID Порта: "$port_id
echo "Группы безопасности: `curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_COMPUTE/servers/$uuid_vm | jq -r '.server.security_groups[]'`"
echo '#############################################################'
echo 'ВМ на портале:'
echo $urlq'/client/orders/'$uuid_proj'/servers/'$uuid_vm_portal
echo 'Консоль VNC:'
vnc=`curl --silent -k -X POST $OS__EP_URL_COMPUTE/servers/$uuid_vm/action \
	-H "Accept: application/json" -H "Content-Type: application/json" \
	-H "User-Agent: python-novaclient" -H "X-Auth-Token: $SYS_TOKEN" \
	-H "X-OpenStack-Nova-API-Version: 2.1" -d '{"os-getVNCConsole": {"type": "novnc"}}'`
echo $vnc | cut -c 39-155 | sed 's/\"}}//g'
echo '#############################################################'

while [ -n "$3" ]
do
	case "$3" in
	  -log)
		echo 'Лог событий совершенных с ВМ:'
		curl --silent -k -X GET $OS__EP_URL_COMPUTE/servers/$uuid_vm/os-instance-actions \
			-H "X-Auth-Token: $SYS_TOKEN" | \
			jq -r '.instanceActions[] | "Событие \(.action) \n\(.request_id) \n\(.start_time)"' ;;
	  -cred)
		echo 'Креды для доступа в ВМ:'
		echo '------------------------------'
		curl --silent -k -X GET -H 'Accept: application/json' \
			-H "Authorization: Bearer $portal_token" \
			$urlq/api/v1/servers/$uuid_vm_portal | \
			jq -r '.server | "Логин: \(.user) \nПароль: \(.password)"'	
		echo '------------------------------'
		;;
	  -dm)
		  echo "Список блочных устройств ВМ:"
		  sudo ssh -i .ssh/1234 $iphyp "sudo virsh domblklist $hypname | tail -n +3 ; exit 0" ;;
	  -bind)
		  echo "Проверка задублированных портов:"
		  curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_NETWORK/v2.0/ports/$port_id/bindings | jq -r ;;
	  -sec)
		  echo "Правила в группах безопасности ВМ:"
		  for sec in `curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_NETWORK/v2.0/ports/$port_id | jq -r .port.security_groups[]`
		  do
			curl --silent -k -X GET -H "X-Auth-Token: $SYS_TOKEN" $OS__EP_URL_NETWORK/v2.0/security-groups/$sec | \
				jq -r '.security_group | "\(.name) \(.security_group_rules[] | "\(.id) \(.direction) \(.protocol) \(.port_range_min) \(.port_range_max) \(.remote_ip_prefix)")"'
			echo "-----------------------------"
	  	  done
		;;
	  *)
		echo "Неверный аргумент $2. Используйте -l для дополнительного вывода логов по ВМ"
		exit 1
		;;
	esac
	shift
done

exit 0
