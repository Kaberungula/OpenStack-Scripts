# !/bin/bash
rm resourse.tmp > /dev/null 2>&1

if [[ -n `echo $OS_AUTH_URL | grep -o "/v3$"` ]]; then 
  OS_AUTH_URL=`echo $OS_AUTH_URL | sed -e 's/\/v3//g'`
fi

#SYS_TOKEN=`curl --silent -i -k -X POST $OS_AUTH_URL/v3/auth/tokens -d '{"auth":{"identity":\
#	{"methods":["password"],"password":{"user":{"name": "'$OS_USERNAME'", "domain":{"name": "default"}, "password": "'$OS_PASSWORD'"}}}}}' \
#		-H 'Content-type: application/json' | awk -F ':' '/^x-subject-token/ {print $2}' | sed -e 's/\r$//'`

SYS_TOKEN=`openstack token issue -f value -c id`

OS__EP_URL_PLACEMENT=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public \
	| jq -r .endpoints[].url | grep '8780'`
OS__EP_URL_COMPUTE=`curl --silent -k -X GET  -H "X-Auth-Token: $SYS_TOKEN" $OS_AUTH_URL/v3/endpoints?interface=public \
  | jq -r .endpoints[].url | grep "8774/v2.1"`
echo "===$OS_REGION_NAME==="
cases=`curl --silent -k -X GET $OS__EP_URL_COMPUTE/os-aggregates -H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r .aggregates[].name`
echo $cases | sed -e s/\ /\\n/g

read -p "Задайте агрегацию для работы: " aggregate

if [[ -z $aggregate ]] || [[ `echo $cases | sed 's/\ /\\n/g' | grep -x $aggregate` != "$aggregate" ]]; then
	echo "Не указана агрегация или задана не верно"
	exit 1;
fi

in_aggr=`openstack aggregate show $aggregate -f json | jq -r .hosts[]`
total_mem_allowed=0

function progress () {
local percent=${1}
local max_bar=${2}
local width=$(( ${percent} * 100 / ${max_bar} ))

local bar=""
while [ ${#bar} -lt ${width} ] ; do bar="${bar}>"; done;
while [ ${#bar} -lt ${max_bar} ] ; do bar="${bar} "; done;
while [ ${#percent} -lt 3 ] ; do percent=" ${percent}"; done;

echo -ne "[${bar} ${width}%]\r"
}

value=1;
len_str=`echo $in_aggr | wc -w`

for each in $in_aggr;
do
  progress ${value} ${len_str}
  sleep 0.05
  (( value++ ))
  hypervisor_state=`curl --silent -k -X GET $OS__EP_URL_COMPUTE/os-hypervisors/$each/search \
    -H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN" | jq -r .hypervisors[].status`
	res_provider_list=`curl --silent -k -X GET $OS__EP_URL_PLACEMENT/resource_providers -H "Accept: application/json" \
		-H "X-Auth-Token: $SYS_TOKEN" | jq -r '.resource_providers | .[] | "\(.uuid) \(.name)"' \
			| grep $each | egrep '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' -o`
	res_provider=`curl --silent -k -X GET $OS__EP_URL_PLACEMENT/resource_providers/$res_provider_list/inventories \
    -H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN"`
  res_usages=`curl --silent -k -X GET $OS__EP_URL_PLACEMENT/resource_providers/$res_provider_list/usages \
    -H "Accept: application/json" -H "X-Auth-Token: $SYS_TOKEN"`
  alc_ratio_cpu=`echo $res_provider | jq -r '.inventories.VCPU | .allocation_ratio'`
	alc_ratio_mem=`echo $res_provider | jq -r '.inventories.MEMORY_MB | .allocation_ratio'`
  total_cpu=`echo $res_provider | jq -r '.inventories.VCPU | .total'`
  total_mem=`echo $res_provider | jq -r '.inventories.MEMORY_MB | .total'`
  used_cpu=`echo $res_usages | jq -r .usages.VCPU`
	used_mem=`echo $res_usages | jq -r .usages.MEMORY_MB`
  calc_allocation_cpu=`echo "$total_cpu * $alc_ratio_cpu" | bc | sed -e 's/\.0//g'`
 	calc_allocation_mem=`echo "$total_mem * $alc_ratio_mem" | bc`
  total_cpu_allowed=$(($total_cpu_allowed + $calc_allocation_cpu))
	total_mem_allowed=`echo "$total_mem_allowed + $calc_allocation_mem" | bc`	
  total_cpu_used=$(($total_cpu_used + $used_cpu))
  total_mem_used=$(($total_mem_used + $used_mem))
  free_cpu_unit=$(($calc_allocation_cpu - $used_cpu))
  free_mem_unit=`echo "$calc_allocation_mem - $used_mem" | bc | sed -e 's/\..*//'`

  echo "$each $free_cpu_unit $calc_allocation_cpu `echo "$free_mem_unit / 1024" | bc` `echo "$calc_allocation_mem / 1024" | bc | sed -e 's/\..*//'` $alc_ratio_cpu $alc_ratio_mem" $hypervisor_state >> resourse.tmp

done

total_cpu_free=`echo "$total_cpu_allowed - $total_cpu_used" | bc`
total_mem_free=`echo "$total_mem_allowed - $total_mem_used" | bc`
#echo "Итого vCPU всего в агрегате $aggregate: $total_cpu_allowed"
#echo "Итого MEM всего в агрегате $aggregate: $total_mem_allowed"
#echo "Итого vCPU в агрегате $aggregate использовано: $total_cpu_used"
#echo "Итого MEM в агрегате $aggregate использовано: $total_mem_used=$(($total_mem_used / 1024)) Gb"
#echo "Итого vCPU в агрегате $aggregate осталось свободно: $total_cpu_free"
#echo "Итого MEM в агрегате $aggregate осталось свободно: `echo "$total_mem_free / 1024" | bc` Gb"

###Table
echo ""
seperator=+---------------------------------------------------
seperator=$seperator$seperator
rows="| %-8s| %-15s| %-15s| %-15s|\n"
TableWidth=62

printf "%.${TableWidth}s\n" "$seperator"
printf "| %-8s| %-15s| %-15s| %-15s|\n" - Total Used Free
printf "%.${TableWidth}s\n" "$seperator"
printf "$rows" "vCPU" $total_cpu_allowed $total_cpu_used $total_cpu_free
printf "$rows" "MEM(Gb)" `echo "$total_mem_allowed / 1024" | bc` `echo "$total_mem_used / 1024" | bc` `echo "$total_mem_free / 1024" | bc`
printf "%.${TableWidth}s\n" "$seperator"
###Table

###Table
seperator=----------------------------------------------------------------------
seperator=$seperator$seperator
rows="| %-40s| %-12s| %-12s| %-12s| %-12s | %-13s | %-10s| %-10s|\n"
TableWidth=165

printf "%.${TableWidth}s\n" "$seperator"
printf "| %-40s| %-12s| %-12s| %-12s| %-12s| %-15s| %-10s| %-10s|\n" Hostname Free_CPU Total_vCPU Free_MEM_GB Total_MEM_GB Alloc_CPU Alloc_MEM State
printf "%.${TableWidth}s\n" "$seperator"
while IFS= read -r line
do
  printf "$rows" `echo $line`
done < resourse.tmp
printf "%.${TableWidth}s\n" "$seperator"
###Table

rm resourse.tmp

exit 0