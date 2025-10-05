#!/bin/bash
# Optimisation tools for Linux boot time (systemd-based)

echo "
███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗██████╗     ██████╗  ██████╗  ██████╗ ████████╗    ████████╗██╗███╗   ███╗███████╗
██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗    ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝    ╚══██╔══╝██║████╗ ████║██╔════╝
███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║██║  ██║    ██████╔╝██║   ██║██║   ██║   ██║          ██║   ██║██╔████╔██║█████╗  
╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██║  ██║    ██╔══██╗██║   ██║██║   ██║   ██║          ██║   ██║██║╚██╔╝██║██╔══╝  
███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║██████╔╝    ██████╔╝╚██████╔╝╚██████╔╝   ██║          ██║   ██║██║ ╚═╝ ██║███████╗
╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═════╝     ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝          ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝
                                                                                                                                       
 ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗███████╗██████╗                                                                     
██╔═══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██║╚══███╔╝██╔════╝██╔══██╗                                                                    
██║   ██║██████╔╝   ██║   ██║██╔████╔██║██║  ███╔╝ █████╗  ██████╔╝                                                                    
██║   ██║██╔═══╝    ██║   ██║██║╚██╔╝██║██║ ███╔╝  ██╔══╝  ██╔══██╗                                                                    
╚██████╔╝██║        ██║   ██║██║ ╚═╝ ██║██║███████╗███████╗██║  ██║                                                                    
 ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝        
 
-Github: yash145-gpu                                                             
                                                                                         "

if ! command -v systemd-analyze &> /dev/null; then
    echo "systemd utilities not found. Install systemd tools first."
    exit 1
fi

times=($(systemd-analyze | grep -oE '[0-9]+\.[0-9]+'))

count=${#times[@]}

echo "Boot sequence time"

if [[ $count -eq 6 ]]; then
    printf "\nFirmware : %s\nLoader   : %s\nKernel   : %s\nUserspace: %s\nTotal    : %s\ngraphical.target reached after %s in userspace.\n\n" \
            "${times[0]}" "${times[1]}" "${times[2]}" "${times[3]}" "${times[4]}" "${times[5]}"

elif [[ $count -eq 7 ]]; then
    printf "\nFirmware : %s\nLoader   : %s\nKernel   : %s\nInitrd   : %s\nUserspace: %s\nTotal    : %s\ngraphical.target reached after %s in userspace.\n\n" \
        "${times[0]}" "${times[1]}" "${times[2]}" "${times[3]}" "${times[4]}" "${times[5]}" "${times[6]}"
else
    echo "Unexpected systemd-analyze format (got $count numbers)"
fi




echo ""
read -p "Do you want to proceed for optimizations? (y/n):" choice
if [[ "$choice" == "y" ]]; then

echo "[2] Top 10 slowest services:"
systemd-analyze blame | grep -vE "dev-disk|dev-tty|dev-tp|sys-" | head -n 10

echo ""

read -p "Check services enabled at boot? (y/n)" choice
if [ "$choice" == "y" ]; then
echo "[3] Services enabled at boot:"
systemctl list-unit-files --state=enabled --no-pager

echo ""
read -p "Do you want to disable unnecessary services? (Making services start manually) y/n): " choice
if [[ "$choice" == "y" ]]; then
    echo "Enter services to disable (space-separated), e.g.: bluetooth.service cups.service"
    read -a services
    for svc in "${services[@]}"; do
        echo "Disabling $svc ..."
        sudo systemctl disable "$svc"
        sudo systemctl stop "$svc"
    done
    echo "Services disabled. Reboot to see changes."
fi
fi
echo ""
read -p "Do you want to clear old journal logs (Reduces log bloat)? (y/n): " clearlogs
if [[ "$clearlogs" == "y" ]]; then
    sudo journalctl --vacuum-size=200M
    echo "Old logs cleared."
fi

echo ""
echo " Boot optimisation complete. Run this script again after reboot to check boot time status."
fi
