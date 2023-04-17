#!/bin/bash


users=(
  public
)




for user in ${users[@]}; do

    user_uuid=$(cat uuid.txt | grep $user | awk '{print $2}')
#     echo -e "$user = $user_uuid \n"
    sudo cp sample.yamls "$user".yaml
    sudo cp sample-proxies.yamls "$user-proxies.yaml"
    sudo sed -i "s#__USER__#$user#" "$user".yaml
    sudo sed -i "s#__USER__#$user#" "$user".yaml
    sudo sed -i "s#__UUID__#$user_uuid#" "$user".yaml
    sudo sed -i "s#__UUID__#$user_uuid#" "$user-proxies.yaml"


    echo -e "==================\n"
    echo -e "USER: $user"
    echo -e "Clash Subscription: https://$user:$user_uuid@subscription.bea.sh/bitmax/$user.yaml \n"
    echo -e "Import to V2RAY:"
    echo -e "trojan://$user_uuid@snapp.ir:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.analifood.ir&fp=chrome&type=ws&sni=max.analifood.ir#Arvan-SNAPP"
    echo -e "trojan://$user_uuid@max.analifood.ir:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.analifood.ir&fp=chrome&type=ws&sni=max.analifood.ir#Arvan"
    echo -e "trojan://$user_uuid@mtn.bea.wiki:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.bea.wiki&fp=chrome&type=ws&sni=max.bea.wiki#IRANCELL"
    echo -e "trojan://$user_uuid@mci.bea.wiki:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.bea.wiki&fp=chrome&type=ws&sni=max.bea.wiki#HamrahAval"
    echo -e "trojan://$user_uuid@ztl.bea.wiki:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.bea.wiki&fp=chrome&type=ws&sni=max.bea.wiki#Zitel"
    echo -e "trojan://$user_uuid@mkh.bea.wiki:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.bea.wiki&fp=chrome&type=ws&sni=max.bea.wiki#Mokhaberat"
    echo -e "trojan://$user_uuid@mbt.bea.wiki:443?path=%2Ftr-ws-IqYJAouF&security=tls&host=max.bea.wiki&fp=chrome&type=ws&sni=max.bea.wiki#Mobinnet"

    echo -e ""



#     sleep 1
done


