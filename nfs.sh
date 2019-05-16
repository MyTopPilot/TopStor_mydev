#!/bin/sh
export ETCDCTL_API=3
enpdev='enp0s8'
pool=`echo $@ | awk '{print $1}'`
vol=`echo $@ | awk '{print $2}'`
ipaddr=`echo $@ | awk '{print $3}'`
ipsubnet=`echo $@ | awk '{print $4}'`
clearvol=`./prot.py clearvol $volname | awk -F'result=' '{print $2}'`
if [ $clearvol != '-1' ];
then
 docker stop $clearvol 
 docker container rm $clearvol 
 /sbin/pcs resource delete --force $clearvol  2>/dev/null
fi
redvol=`./prot.py redvol $volname | awk -F'result=' '{print $2}'`
if [ $redvol != '-1' ];
then
 redipaddr=`echo $redvol | awk -F'-' '{print $NF}'`
 /TopStor/delblock.py ${vol} ${vol} /TopStordata/exports.$redipaddr ;
 cp /TopStordata/exports.${redipadrr}.new /TopStordata/exports.$redipaddr
 docker exec -it $redvol exportfs -ra 
fi
rightvol=`/pace/etcdget.py ipaddr/$ipaddr`
if [ $rightvol -eq '-1' ];
then
 resname=nfs-$pool-$ipaddr
 /pace/etcdput.py ipaddr/$ipaddr $resname/$vol 
 /pace/broadcasttolocal.py ipaddr/$ipaddr $resname/$vol 
 echo $@ > /root/nfsparam
 docker stop $resname
 docker container rm $resname
 yes | cp /etc/{passwd,group,shadow} /opt/passwds
 cp /TopStordata/exports.${vol} /TopStordata/exports.$ipaddr
 /sbin/pcs resource delete --force $resname  2>/dev/null
 /sbin/pcs resource create $resname ocf:heartbeat:IPaddr2 ip=$ipaddr nic=$enpdev cidr_netmask=$ipsubnet op monitor interval=5s on-fail=restart
 /sbin/pcs resource group add ip-all $resname
 docker run -d -v /$pool/$vol:/$pool/$vol:rw -v /TopStordata/exports.$ipaddr:/etc/exports:ro \
  --cap-add SYS_ADMIN -p $ipaddr:2049:2049  -p $ipaddr:2049:2049/udp \
  -p $ipaddr:32765:32765 -p $ipaddr:32765:32765/udp \
  -p $ipaddr:111:111 -p $ipaddr:111:111/udp \
  -p $ipaddr:32767:32767 -p $ipaddr:32767:32767/udp \
  -v /opt/passwds/passwd:/etc/passwd:rw \
  -v /opt/passwds/group:/etc/group:rw \
  -v /opt/passwds/shadow:/etc/shadow:rw \
  --name $resname 10.11.11.124:5000/nfs
else
 resname=`echo $rightvol | awk -F'/' '{print $1}'`
 newright=${rightvol}'/'$vol 
 mounts=`echo $newright |sed 's/\// /g'| awk '{$1=""; print}'`
 mount=''
 for x in $mounts; 
 do
  mount=$mount'-v /'$pool'/'$x':/'$pool'/'$x':rw '
 done
 cat /TopStordata/exports.${vol} >> /TopStordata/exports.$ipaddr
 docker stop $resname
 docker rm $resname
 /pace/etcdput.py ipaddr/$ipaddr $newright 
 /pace/broadcasttolocal.py ipaddr/$ipaddr $newright 
 docker run -d $mount -v /TopStordata/exports.$ipaddr:/etc/exports:ro \
  --cap-add SYS_ADMIN -p $ipaddr:2049:2049  -p $ipaddr:2049:2049/udp \
  -p $ipaddr:32765:32765 -p $ipaddr:32765:32765/udp \
  -p $ipaddr:111:111 -p $ipaddr:111:111/udp \
  -p $ipaddr:32767:32767 -p $ipaddr:32767:32767/udp \
  -v /opt/passwds/passwd:/etc/passwd:rw \
  -v /opt/passwds/group:/etc/group:rw \
  -v /opt/passwds/shadow:/etc/shadow:rw \
  --name $resname 10.11.11.124:5000/nfs
fi
