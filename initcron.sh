myhost=`hostname -s`
myip=`cat /etc/hosts | grep $myhost | head -1 | awk '{print $1}'`
ETCDCTL_API=3 /pace/nodesearch.py  $myip  > /pacedata/nodesearch.txt
systemctl start pacemaker
sleep 120 
/sbin/pcs resource delete --force IPinit
/sbin/ip addr del 10.11.11.254/24 dev enp0s8 
/TopStor/factory.sh


