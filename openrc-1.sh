for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
fname=$(basename $BASH_SOURCE)
mkdir tokens > /dev/null 2>&1
export OS_AUTH_URL=
export OS_PROJECT_ID=814935ad94ec7b7a85ce1d621240f
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_USERNAME=
export OS_PASSWORD=
export OS_REGION_NAME="One"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3
export OS_CACERT=
export SYS_TOKEN=$(cat tokens/token_$fname.txt) > /dev/null 2>&1

check_token=`curl --silent -k -I $OS_AUTH_URL/v3/auth/tokens \
	        -H "X-Auth-Token: $SYS_TOKEN" -H "x-subject-token: $SYS_TOKEN" | \
		        grep 'OK' | sed -e 's/.*[HTTP/1.1 200]//g' -e 's/\r$//'`

if [[ $check_token != "OK" ]]; then
	        echo 'Токен не активен. Будет выпущен новый...'
	        `curl --silent -i --cacert "$OS_CACERT" \
	                -X POST $OS_AUTH_URL/v3/auth/tokens -d '{"auth":{"identity":\
		                {"methods":["password"],"password":{"user":{"name": "'$OS_USERNAME'", "domain":\
		                        {"name": "default"}, "password": "'$OS_PASSWORD'"}}}}}' \
		                                -H 'Content-type: application/json' | \
			                                awk -F ':' '/^x-subject-token/ {print $2}' | sed -e 's/\r$//' > tokens/token_$fname.txt`
        export SYS_TOKEN=$(cat tokens/token_$fname.txt) > /dev/null 2>&1
else
        echo 'Токен активен. Выпуск не требуется.'
fi

export OS_EP_URL_CINDERV3=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public | jq -r .endpoints[].url | sed -n '\;8776/v3;s;/%.*;;p'`
export OS_EP_URL_COMPUTE=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public | jq -r .endpoints[].url | grep "8774/v2.1"`
export OS_EP_URL_NETWORK=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public | jq -r .endpoints[].url | grep '9696'`
export OS_EP_URL_KARBOR=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public | jq -r .endpoints[].url | sed -n '\;8799/v1;s;/%.*;;p'`