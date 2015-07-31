#!/bin/bash
# sysinfo.sh, created by Hunter, modified by Jonathan
# Authors:
# Hunterm@irc.efnet.org     [oh hi]
# jmad980@irc.freenode.net  [based script off his]
# e36freak@irc.freenode.net [helped jmad980]
# licensed under the wtfpl, but credit would be cool

# Current modules:
#   - userandhost - Shows your system's current user and its host name. 
#       - Output: hunterm@halla
#   - proc        - Shows your CPU's model.
#       - Output: Intel(R) Core(TM) i3 CPU M 370 @ 2.40GHz
#   - cputype     - Shows if you system is either 32 bit or 64 bit.
#       - Output: 64bit
#   - ram         - Shows the amount of ram used and free.
#       - Output: ram: 1364MB/3757MB 
#   - loadavg     - Shows your system's load average.
#       - Output: loadavg: 0.01 0.12 0.13
#   - kernel      - Shows your current kernel version.
#       - Output: kernel: 3.5.4-1
#   - packages    - Shows how many packages you have installed on your system.
#       - Output: packages: 598
#   - uptime      - Shows how long your system has been on. 
#       - Output: uptime: 5h58m0s
#   - processes   - Shows how many processes are currently running on your system.
#       - Output: proc: 137

# -- configuration
modules="userandhost proc cputype ram loadavg kernel packages uptime processes"
# order matters, don't forget.

# -- output configuration
afterfirstmodule=": "
# this will be appended after the first modules output,
# allows for a nice looking sort of output at the beginning. for example:
# instead of hunterm@halla :: Intel(R) Core(TM) i3 CPU M 370 @ 2.40GHz
# we can have hunterm@halla: Intel(R) Core(TM) i3 CPU M 370 @ 2.40GHz

# each prefix and suffix is by default a single space, because of the way I have
# the format interpreted in the script. this makes it more extendable.
# so, for prefixes, whenever you make a prefix, you should put a space at the end
# without a space, you get output like this:
# hunterm@halla: Intel(R) Core(TM) i3 CPU M 370 @ 2.40GHz .::. 64 bit .::. ram:1364MB/3757MB .::. loadavg:0.35 0.23 0.24 .::. kernel:3.2.8-1 .::. uptime:15h20m24s .::. proc:150
# for suffixes, whenever you make a suffix, you can put a space anywhere, so if
# you happen to have a suffix like this:
# ramsuffix=" I'm going so fast awww yeah "
# it will look like this:
# ram: 1421MB/3757MB I'm going so fast awww yeah



# -- prefixes configuration
# allows you to configure the prefix before the input of each module.
# each one has a separate prefix, as you can see.
ramprefix="ram: "
loadavgprefix="loadavg: "
kernelprefix="kernel: "
uptimeprefix="uptime: "
processesprefix="proc: "
packagesprefix="packages: "

userandhostprefix=""

# -- module format configuration
# some modules have a format you can specify; here's where you can format them.
userandhostformat="$USER@$HOSTNAME"

# -- suffixes configuration
# allows you to configure the suffix after the input of each module.
# each modules has a separate suffix, as with the prefixes.
ramsuffix=" "
loadavgsuffix=" "
kernelsuffix=" "
uptimesuffix=" "
processessuffix=" "
packagessuffix=" "
userandhostsuffix=" "

# this is the separator used in between output. put a space at the begin and end
# to make things look nicer.
separator=" .::. "



# -- actual script, don't touch unless you know what you're doing

if [[ ! -z "$1" ]];then
    ssh "$1" "$(cat $0)"
    exit
fi

for packagemanager in pacman dpkg;do
    if [[ ! -z "$(which $packagemanager 2>/dev/null)" ]]; then
        case "$packagemanager" in
            pacman)
            packages=$(pacman -Qq | wc -l)
            kernel_version=$(pacman -Q linux 2>/dev/null || pacman -Q kernel26 2>/dev/null)
            kernel_version="${kernel_version##* }"
            ;;
            dpkg)
            packages=$(dpkg -l | wc -l)
            kernel_version=$(echo $(dpkg --list linux-base 2>/dev/null | tail -1) | cut -d' ' -f3)
            ;;
            *)
            packages="('couldn't find amount')"
            kernel_version=$(uname -a | awk '{print $3;}')
            ;;
        esac
    fi
done

OLDIFS=$IFS
IFS=' '
uptime=( $(</proc/uptime) )
uptime=${uptime[0]}
IFS=.
uptime=( $(</proc/uptime) )
uptime=${uptime[0]}
secs=$(( $uptime % 60 ))
mins=$(( $uptime / 60 % 60 ))
hours=$(( $uptime / 3600 % 24 ))
days=$(( $uptime / 640000 ))
# Why the heck would I ever attempt to parse `uptime` output? It's so gross.

if [[ ! $days -eq 0 ]];then
    uptime="${days}d${hours}h${mins}m${secs}s"
else
    uptime="${hours}h${mins}m${secs}s"
fi

if [[ "$HOSTTYPE" == "x86_64" ]];then
    cputype="64 bit"
elif [[ "$HOSTTYPE" == "i686" ]];then
    cputype="32 bit"
else
    cputype="$HOSTTYPE"
fi

# collecting memory info
free=$(free -m)
mem_free=$(echo "$free" | awk '/cache:/{print $3}' | tail -n1)
mem_total=$(echo "$free" | awk '/^Mem/{print $2}')
# collecting proc info
proc=$(grep "model name" /proc/cpuinfo | head -n1)
proc="${proc##*: }"
proc="${proc/      }"
proc="${proc/ @/@}"

load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)
processes=$(ps aux 2>/dev/null | wc -l)

# prettying it up...
ram="$ramprefix${mem_free}MB/${mem_total}MB$ramsuffix"
loadavg="$loadavgprefix${load}$loadavgsuffix"
kernel="$kernelprefix$kernel_version$kernelsuffix"
uptime="$uptimeprefix$uptime$uptimesuffix"
processes="$processesprefix$processes$processessuffix"
packages="$packagesprefix$packages$packagessuffix"
userandhost="$userandhostformat"

IFS=" "

# module stuff
for module in $modules; do
    if [[ $module == "$(echo $modules | cut -d ' ' -f1)" ]];then
        string=$(eval "echo "\$$module"")"$afterfirstmodule"
    elif [[ "$module" == "space" ]];then
        string="$string "
    elif [[ "$module" == "separator" ]];then
        string="$string$separator"
    else
        string="$string"$(eval "echo "\$$module"")"$separator"
    fi
done
string=$(echo "$string" | sed "s/$separator$//")  
printf "$string\n"
IFS="$OLDIFS"