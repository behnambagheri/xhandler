#!/bin/bash


users=(
  public
)





for user in ${users[@]}; do
    echo $user
    uuidgen
    echo
    sleep 1
done


