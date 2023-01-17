#! /bin/bash 

curl --silent -X GET -H 'Content-Type: application/json' 'http://1.1.1.53:7000/hap?stats;csv;norefresh' > 12345677.csv
curl --silent -X GET -H 'Content-Type: application/json' 'http://1.1.1.58:7000/hap?stats;csv;norefresh' > 123456777.csv

echo "----=====HAproxy-s3-01=====----"
while IFS="," 
	read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime agent_status agent_code agent_duration check_desc agent_desc check_rise check_fall check_health agent_rise agent_fall agent_health addr cookie mode algo conn_rate conn_rate_max conn_tot intercepted dcon dses wrew connect reuse cache_lookups cache_hits srv_icur src_ilim qtime_max ctime_max rtime_max ttime_max eint idle_conn_cur safe_conn_cur used_conn_cur need_conn_est 
do 
	echo -n "$svname | "
	echo -n "status: $status | "
	echo -n "check_status: $check_status | "
	echo -n "hrsp_5xx: $hrsp_5xx | "
	echo "" 
done < <(tail -n +6 12345677.csv)

echo "----=====HAproxy-s3-02=====----"
while IFS="," 
	read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime agent_status agent_code agent_duration check_desc agent_desc check_rise check_fall check_health agent_rise agent_fall agent_health addr cookie mode algo conn_rate conn_rate_max conn_tot intercepted dcon dses wrew connect reuse cache_lookups cache_hits srv_icur src_ilim qtime_max ctime_max rtime_max ttime_max eint idle_conn_cur safe_conn_cur used_conn_cur need_conn_est 
do 
	echo -n "$svname | "
	echo -n "status: $status | "
	echo -n "check_status: $check_status | "
	echo -n "hrsp_5xx: $hrsp_5xx | "
	echo "" 
done < <(tail -n +6 123456777.csv)

rm 12345677.csv
rm 123456777.csv


echo "----=====Radosgw STATUS=====----"
echo "radosgw-okvm-05:" `ssh 1.1.1.1 'sudo systemctl status radosgw.service | grep Active'`
ssh 1.1.1.1 'sudo top -b -n 1 | head -5'
echo "-----"
echo "radosgw-okvm-04:" `ssh 1.1.1.1 'sudo systemctl status radosgw.service | grep Active'`
ssh 1.1.1.1 'sudo top -b -n 1 | head -5'
echo "-----"
echo "radosgw-okvm-03:" `ssh 1.1.1.1 'sudo systemctl status radosgw.service | grep Active'`
ssh 1.1.1.1 'sudo top -b -n 1 | head -5'
echo "-----"
echo "radosgw-okvm-02:" `ssh 1.1.1.1 'sudo systemctl status radosgw.service | grep Active'`
ssh 1.1.1.1 'sudo top -b -n 1 | head -5'
echo "-----"
echo "radosgw-okvm-01:" `ssh 1.1.1.1 'sudo systemctl status radosgw.service | grep Active'`
ssh 1.1.1.1 'sudo top -b -n 1 | head -5'

echo "----=====List Backets=====----"
time aws s3api --profile 1-kvm-admin --endpoint https://s3.name.dev list-buckets
time aws s3api --profile s3_a615dc6f-c912-4b84-843b-f35c0c185746 --endpoint https://s3.name.dev list-buckets


exit 0
