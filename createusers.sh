#! /bin/bash

for each in `cat userlist.csv | awk 'FNR>1' | sed -e 's/ /_/g'`
do
	while IFS=";" read -r r1 r2 r3 r4 r5 r6 r7
	do
		desc=`echo $r1 | sed -e 's/\r$//' -e 's/^/"/;s/$/"/'`
		email=`echo $r2 | sed -e 's/\r$//' -e 's/^/"/;s/$/"/'`
		login=`echo $r3 | sed -e 's/\r$//' -e 's/^/"/;s/$/"/'`
		pass=`echo $r4 | sed -e 's/\r$//' -e 's/^/"/;s/$/"/'`
		uuid=`echo $r5 | sed -e 's/\r$//'`
		roles=`echo $r6 | sed -e 's/\r$//'`
	done < <(echo $each)

	loginx=`echo $login | sed -e 's/"/''/g'`	
	ex_user=`curl --silent --cacert $OS_CACERT \
		-X GET $OS_AUTH_URL/v3/users?name=$loginx \
		-H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.users[].name'`
	
		if [[ -z $ex_user ]];then
			role=`curl --silent -g --cacert $OS_CACERT -X GET $OS_AUTH_URL/v3/roles?name=$roles \
				-H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.roles[].id'`
			id=`curl --silent -k -X GET $OS_AUTH_URL/v3/projects?name=$uuid \
				-H "X-Auth-Token: $SYS_TOKEN" | jq '.projects[].id'`

			if [[ -n $id ]] && [[ -n $role ]]; then
				echo "Создание УЗ $desc"
				`curl --silent --cacert "$OS_CACERT" -X POST $OS_AUTH_URL/v3/users \
					-d '{ "user": { "default_project_id": '$id', "enabled": false, "name": '$login', "password": '$pass', "description": '$desc', "email": '$email'}}' -H 'Content-type: application/json' -H "X-Auth-Token: $SYS_TOKEN" \
					| jq -r '.user | "Логин: \(.name) \nЕмаил: \(.email) \nОписание \(.description) \nПроект: \(.default_project_id) \nID Пользователя: \(.id)"' > log.tmp`
				date >> createlog.txt
				cat log.tmp >> createlog.txt
				echo '-----------------------' >> createlog.txt
				usr_id=`cat log.tmp | cut -c 30-61 | tail -n1`
				rm -f log.tmp
				ids=`echo $id | sed -e 's/"/''/g'`
				curl --silent --cacert "$OS_CACERT" \
					-X PUT $OS_AUTH_URL/v3/projects/$ids/users/$usr_id/roles/$role \
					-H 'Content-type: application/json' -H "X-Auth-Token: $SYS_TOKEN"
			else
				echo -e "\033[0m\033[0m\033[31mПроект $uuid не найден на запрошенной стойке, либо не верно указана роль.\nДоступно: admin или member. Невозможно добавить УЗ пользователя $desc \033[0m"
			fi
		else
			echo -e "\033[34mУЗ $desc уже существует \033[0m"
			check_not_only_uuid=`cat userlist.csv | grep $loginx | egrep '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' -o | sed -n '2p'`
			if [[ -n $check_not_only_uuid ]]; then
#                        	echo "Пользователь $desc будет добавлен в заданные проекты"
				only_proj_uuid=`cat userlist.csv | grep -w $loginx | egrep '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' -o`
				for each_id in $only_proj_uuid;
				do
					ids=`curl --silent -k -X GET $OS_AUTH_URL/v3/projects?name=$each_id \
						        -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.projects[].id'`
					if [[ -n `echo $ids` ]]; then
						usr_id=`curl --silent --cacert "$OS_CACERT" -X GET $OS_AUTH_URL/v3/users?name=$loginx \
							-H 'Content-type: application/json' -H "X-Auth-Token: $SYS_TOKEN" | jq -r .users[].id`
						role=`curl --silent -g --cacert $OS_CACERT -X GET $OS_AUTH_URL/v3/roles?name=$roles \
								-H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.roles[].id'`
						check_membr_inproj=`curl --silent --cacert "$OS_CACERT" -X GET $OS_AUTH_URL/v3/users/$usr_id/projects \
							-H 'Content-type: application/json' -H "X-Auth-Token: $SYS_TOKEN" | jq -r .projects[].name`
						if [[ -z `echo $check_membr_inproj | egrep -o $each_id` ]]; then
							echo "Добавление $desc в проект: $each_id c ролью $roles"
							curl --silent --cacert "$OS_CACERT" \
								-X PUT $OS_AUTH_URL/v3/projects/$ids/users/$usr_id/roles/$role \
								-H 'Content-type: application/json' -H "X-Auth-Token: $SYS_TOKEN"
						else
							echo "Пользователь уже имеет права в проекте: $each_id"
						fi
					fi
				done
				break
			fi
		fi
done
echo "Информация по успешно заведенным УЗ записана в createlog.txt"
exit 0
