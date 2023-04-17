#!/bin/bash

xstats_dir=$HOME/xhandler/bitmax
full_stats=xstats.full
if [ -e full_stats ]; then
    last_stats=$(cat $full_stats)
else
    last_stats=false
fi

servers=(
  server1
  server2
  server3
)


users=(
  public
)

config_file=config.json

xstats(){
get_xstats() {

cd $xstats_dir || exit 0



for server in ${servers[@]}; do

 ssh $server '/usr/local/bin/v2ctl api --server=127.0.0.1:10085 StatsService.QueryStats "reset: true"' \
    | awk '{
        if (match($1, /name:/)) {
            f=1; gsub(/^"|link"$/, "", $2);
            split($2, p,  ">>>");
            printf "%s:%s->%s\t", p[1],p[2],p[4];
        }
        else if (match($1, /value:/) && f){ f = 0; printf "%.0f\n", $2; }
        else if (match($0, /^>$/) && f) { f = 0; print 0; }
    }' | grep user


done




}

collect_data(){

rm -f /tmp/usage.tmp
get_xstats > /tmp/usage.tmp
if [ -e ./usage.old ]; then
    cat ./usage.old >> /tmp/usage.tmp
fi





for user in ${users[@]}; do

    up=$(cat /tmp/usage.tmp | grep -E "${user}.*up" | awk '{print $2}')
    tot_up=0
    for i in ${up[@]}; do
        tot_up=$(($i+$tot_up))
    done

    down=$(cat /tmp/usage.tmp | grep -E "${user}.*down" | awk '{print $2}')
    tot_down=0
    for i in ${down[@]}; do
        tot_down=$(($i+$tot_down))
    done




    echo "USER: $user | UP: $tot_up | DOWN: $tot_down" \
        | numfmt --field=5,8 --suffix=B --to=iec | tr -s " "


    echo "USER: $user | UP: $tot_up | DOWN: $tot_down" \
        | numfmt --field=5,8 --suffix=B --to=iec | tr -s " " >> xstats.full

done

cp /tmp/usage.tmp ./usage.old


}




collect_data

}


xlogs() {


xlog_dir=$HOME/xhandler/bitmax/
mDATE=$(date +%F)


cd $xlog_dir


for server in ${servers[@]}; do
    scp $server:/var/log/v2ray/access.log $server.$mDATE-log
    sleep 1
done

grep -v 'api -> api\|\[api]\|rejected' *.$mDATE-log | sed  's/log:/log : /g' | sed -e "s/${mDATE}-log//g" | sed -e "s/. :/ :/g" | sort -u  -k3 > $mDATE.xlog

echo 6
for server in ${servers[@]}; do
    rm $xlog_dir/$server.$mDATE-log
done

echo 7

for server in ${servers[@]}; do
    ssh $server 'cp /var/log/v2ray/access.log /var/log/v2ray/access.log-$mDATE && echo "" > /var/log/v2ray/access.log && chown -R nobody:nobody /var/log/v2ray/access.log'
done



}

update_config(){


for server in ${servers[@]}; do
    scp $config_file $server:/usr/local/etc/v2ray/config.json
    ssh $server 'systemctl restart v2ray'
done

}

case $1 in
    xlog)
        xlogs
        ;;
    xstat)
        xstats
        ;;
    config)
        xstats
        sleep 5
        update_config
        ;;
    "")
        echo error
        exit 1
        ;;
    *)
        echo error
        exit 1
        ;;
esac





