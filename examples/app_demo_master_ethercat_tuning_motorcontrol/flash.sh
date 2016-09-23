#! /bin/bash
#


dev=eth0

number=1
#getops
while getopts ":n:c:s:i:hf:e:" opt; do
    case $opt in
        i) input="$OPTARG" ;;
        n) number="$OPTARG" ;;
        c) oldsii="$OPTARG" ;;
        s) newsii="$OPTARG" ;;
        f) flash="$OPTARG" ;;
        e) ethercat="$OPTARG" ;;
        h) help=1 ;;
        \?) { echo "Invalid option: -$OPTARG" >&2 ; exit 1; } ;;
        :) { echo "Option -$OPTARG requires an argument." >&2; exit 1; } ;;
    esac
done

if [ ! -e "$input" -o ! -e "$oldsii" -o ! -e "$newsii" -o ! -e "$flash" -o -z "$ethercat" ];then
    help=1
fi

#help
if [ "$help" ];then #\033[0;31mError in muxing!\033[0m red
    echo -e \
'-i: file to flash\n'\
'-n: number of nodes\n'\
'-c: old sii file CiA402-mk2-noEoE.sii\n'\
'-s: new sii file Somanet_ECAT-v3r0.sii\n'\
'-f: flash command\n'\
'-f: ethercat driver command\n'\
'-h: display this help\n'\
'example:\n'\
'./flash -f ./fwupdate -e /etc/init.d/ethercat -c CiA402-mk2-noEoE.sii -s Somanet_ECAT-v3r0.sii -i tuning.bin -n 6'
    exit 0
fi

siiwrite() {
    for ((i=0; i < "$2" ; i++)); do
        ethercat sii_write -p "$i" "$1"
        echo -n
    done
}

echo "$(tput setaf 2)flashing old eeprom$(tput sgr0)"
siiwrite "$oldsii" "$number"

echo "$(tput setaf 1)Please power cycle$(tput sgr0)"
sudo "$ethercat" stop
read


if [ "$number" -gt 1 ];then
    echo "$(tput setaf 2)flashing all connected nodes$(tput sgr0)"
    sudo "$flash" "$dev" -all "$input"
else
    echo "$(tput setaf 2)flashing only first node$(tput sgr0)"
    sudo "$flash" "$dev" -seq 0 "$input"
fi

echo "$(tput setaf 1)Please power cycle$(tput sgr0)"
sudo "$ethercat" start
read

echo "$(tput setaf 2)flashing new eeprom$(tput sgr0)"
siiwrite "$newsii" "$number"

echo "$(tput setaf 1)Please power cycle$(tput sgr0)"
read


exit 0;
