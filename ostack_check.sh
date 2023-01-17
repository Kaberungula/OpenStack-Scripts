#! /bin/bash 


function vars {
 echo ""
 echo "Volume service in down or up"
 curl --silent -k -X GET $OS_EP_URL_CINDERV3/$OS_PROJECT_ID/os-services -H "Accept: application/json" \
       -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.services[] | "\(.binary) \(.host) \(.status) \(.state)"' | grep -E "down|disabled"
 echo "Compute service in down or up"
 curl --silent -k -X GET "$OS_EP_URL_COMPUTE/os-services" -H "Accept: application/json" \
       -H "X-Auth-Token: $SYS_TOKEN" | jq -r '.services[] | "\(.binary) \(.host) \(.status) \(.state) \(.disabled_reason)"' | grep -E "down|disabled"
}

function addnum {
while IFS="," 
	read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime agent_status agent_code agent_duration check_desc agent_desc check_rise check_fall check_health agent_rise agent_fall agent_health addr cookie mode algo conn_rate conn_rate_max conn_tot intercepted dcon dses wrew connect reuse cache_lookups cache_hits srv_icur src_ilim qtime_max ctime_max rtime_max ttime_max eint idle_conn_cur safe_conn_cur used_conn_cur need_conn_est 
do
  echo -n "$pxname | "	
	echo -n "$svname | "
	echo -n "status: $status | "
	echo -n "check_status: $check_status | "
	echo -n "hrsp_5xx: $hrsp_5xx | "
	echo "" 
done < <(tail -n +6 $1)
}

while [ -n "$1" ]
do
        case "$1" in
          -er1)
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er1.csv
              val1="er1.csv"
              addnum $val1
              rm er1.csv
              source ./openrc-1.sh > /dev/null 2>&1
              vars
              ;;
          -er2)
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er2.csv
              val2="er2.csv"
              addnum $val2
              rm er2.csv
              source ./openrc-2.sh > /dev/null 2>&1
              vars
              ;;
          -er3)
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er3.csv
              val3="er3.csv"
              addnum $val3
              rm er3.csv
              source ./openrc-3.sh > /dev/null 2>&1
              vars
              ;;
            -all)
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er1.csv
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er2.csv
              ssh 1.1.1.1 "curl --silent -X GET -u openstack:pass -H 'Content-Type: application/json' 'http://1.1.1.1:1984/hap?stats;csv;norefresh'" > er3.csv

              val1="er1.csv"
              val2="er2.csv"
              val3="er3.csv"

              addnum $val1
              addnum $val2
              addnum $val3

              rm er1.csv
              rm er2.csv
              rm er3.csv

              ;;  
              *)
                echo "Неверный аргумент $2"
                exit 1
                ;;
        esac
        shift
done

exit 0