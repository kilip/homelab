#!/bin/bash
while true
do
    if on_ac_power; then
        ## Laptop on power
        echo "Laptop on power"
    else
        echo "Laptop on battery"
        systemctl suspend          ## Laptop on battery
    fi
    sleep 1                       ## wait 10 sec before repeating
done
