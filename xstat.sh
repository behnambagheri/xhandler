#!/bin/bash
# shellcheck disable=SC2034

# Set some default values:
ENV_FILE="unset"
USERS="unset"
SERVERS="unset"
DEFAULT_DIRECTORY="unset"
TEMP_USAGE_FILE="unset"
CONFIG_FILE="unset"
USAGE_ARCHIVE="unset"
FULL_STATS="unset"

usage()
{
  echo "Usage: xhandler [ -e | --env-file .env ]"
  exit 2
}

xstats(){
get_xstats() {

cd "$DEFAULT_DIRECTORY" || exit 0



for server in "${SERVERS[@]}"; do
  echo -e "server: $server"

 ssh "$server" '/usr/local/bin/v2ctl api --server=127.0.0.1:10085 StatsService.QueryStats "reset: true"' \
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

rm -f $TEMP_USAGE_FILE
get_xstats > $TEMP_USAGE_FILE
if [ -e $USAGE_ARCHIVE ]; then
    cat $USAGE_ARCHIVE >> $TEMP_USAGE_FILE
fi




rm -f $FULL_STATS &> /dev/null
for user in "${USERS[@]}"; do

    local up down tot_up tot_down

    up=$(grep -E "${user}.*up" "$TEMP_USAGE_FILE" | awk '{print $2}')
    tot_up=0
    for i in ${up[@]}; do
        tot_up=$((i+tot_up))
    done

    down=$(grep -E "${user}.*down" "$TEMP_USAGE_FILE" | awk '{print $2}')
    tot_down=0
    for i in ${down[@]}; do
        tot_down=$((i+tot_down))
    done




    echo "USER: $user | UP: $tot_up | DOWN: $tot_down" \
        | numfmt --field=5,8 --suffix=B --to=iec | tr -s " "


    echo "USER: $user | UP: $tot_up | DOWN: $tot_down" \
        | numfmt --field=5,8 --suffix=B --to=iec | tr -s " " >> $FULL_STATS

done

cp $TEMP_USAGE_FILE $USAGE_ARCHIVE


}




collect_data

}


xlogs() {


  local mDATE
  #xlog_dir=$HOME/xhandler/bitmax/
  mDATE=$(date +%F)


  cd "$DEFAULT_DIRECTORY" || exit


  for server in ${SERVERS[@]}; do
      scp "$server":/var/log/v2ray/access.log "$server"."$mDATE"-log
      sleep 1
  done

  if [[ -e "$mDATE".xlog ]]; then
      grep -v 'api -> api\|\[api]\|rejected' *.$mDATE-log | sed  's/log:/log : /g' | sed -e "s/${mDATE}-log//g" | sed -e "s/. :/ :/g" | sort -u  -k3 >> "$mDATE".xlog
    else
      grep -v 'api -> api\|\[api]\|rejected' *.$mDATE-log | sed  's/log:/log : /g' | sed -e "s/${mDATE}-log//g" | sed -e "s/. :/ :/g" | sort -u  -k3 > "$mDATE".xlog
  fi
  

  for server in ${SERVERS[@]}; do
      rm "$DEFAULT_DIRECTORY"/"$server"."$mDATE"-log
  done


  for server in ${SERVERS[@]}; do
      ssh "$server" 'cp /var/log/v2ray/access.log /var/log/v2ray/access.log-$mDATE && echo "" > /var/log/v2ray/access.log && chown -R nobody:nobody /var/log/v2ray/access.log'
  done



}

update_config(){


for server in ${SERVERS[@]}; do
    scp $CONFIG_FILE "$server":/usr/local/etc/v2ray/config.json
    ssh "$server" 'systemctl restart v2ray'
done

}



PARSED_ARGUMENTS=$(getopt -a -n xhandler -o e:lcs --long env-file,stats,logs,config,shit,: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi


source_env(){
  local ENV_FILE
  ENV_FILE=$1
  echo "$1"
  # shellcheck source=./.env.example
  source "$ENV_FILE"
}

#echo "PARSED_ARGUMENTS is $PARSED_ARGUMENTS"
eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -e | --env-file)   source_env "$2"   ; shift 2 ;;
    -s | --stats) xstats ; shift ;;
    -l | --logs) xlogs ; shift ;;
    -c | --config) xstats ; sleep 5 ; update_config ; shift ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    *) echo "Unexpected option: $1 - this should not happen."
       usage ;;
  esac
done

