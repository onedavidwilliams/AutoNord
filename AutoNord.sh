#!/bin/bash

# As I have time(for people learning bash scripting) I will comment and explain as much as possible
# I hope this helps somone learn just a bit quicker and land that job, impress that boss and/or enrich your learning experience.

SPEED_FILE="/tmp/network_speed.tmp"

# Function: find_active_interface
#
# Purpose:
#
# Simple - Returns your active network interface if you have one.
#
# Detailed - This function finds and returns the name of the first active network interface (IPv4 or IPv6) on the system,
# excluding the loopback interface (a fancy term for 'localhost' and includes the 127.*.*.254 range for IPv4 and '::1' for IPv6). 
# It's particularly useful for scripts that require interaction with an active network interface for operations such as 
# monitoring network traffic, without needing manual specification of the interface. Automation my friends!
#
# How it works:
# - Utilizes the `ip` command to list all network interfaces, filtering out the loopback interface ('lo').
# - Parses the output using `awk` to extract interface names.
# - Checks each interface for assigned IPv4 addresses, indicating activity.
# - Returns the name of the first active interface found.
# - If no active interface is found, prints an error message and exits the script with a status of 1.
#
# Commands and Arguments:
# - `ip -o link show`: Lists all network interfaces, with `-o` ensuring one-line output for each interface.
# - `awk -F': ' '{print $2}'`: Parses each line, using ': ' as the field separator, and prints the second field (interface name).
# - `grep -v lo`: Excludes the loopback interface by filtering out lines containing 'lo'.
# - `ip -o -4 addr show $iface`: Shows IPv4 addresses for the interface `$iface`, with `-o` for one-line output, and `-4` for IPv4.
# - `ip -o -6 addr show $iface`: Shows IPv6 addeesses for the interface `$iface`, with `-o` for one-line output, and `-6` for IPv6.
# - `wc -l`: Counts the number of lines in the command output, used here to determine if the interface has IPv4 addresses.
# - `echo $iface`: Outputs the name of the first active interface found.
# - `exit 1`: Exits the script with a status of 1, used to indicate an error if no active interface is found.
#
# Usage:
# This function is designed to be called without any arguments. It automatically detects and outputs
# the first active network interface's name. It's ideal for use in larger scripts where automatic
# interface selection is required.
#
# Example:
# active_interface=$(find_active_interface)
# echo -e "${AN}Active interface: $active_interface"
#
# Note:
# The function assumes that an interface with at least one IPv4 address is "active". This may not
# always align with all definitions or requirements of an active interface, depending on specific
# network configurations or use cases.


find_active_interface() {
    local interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
    for iface in $interfaces; do
        # Check for both IPv4 and IPv6 addresses. An interface is considered active if either check passes.
        if [[ $(ip -o -4 addr show $iface | wc -l) -gt 0 ]] || [[ $(ip -o -6 addr show $iface | wc -l) -gt 0 ]]; then
            echo $iface
            return
        fi
    done
    echo -e "${AN}No active interface found." >&2
    exit 1
}

# Function: monitor_speed
#
# Purpose:
#
# Simple - Measures and records the download and upload speeds of your active network interface.
#
# Detailed - This function continuously monitors the network traffic on the specified interface, calculating the download
# and upload speeds in Mbps (Megabits per second) and saving them to a file. It's designed for scripts that need to monitor network performance, 
# providing real-time insights into the speeds at which data is being received and transmitted. Essential for performance monitoring!
#
# How it works:
# - Enters an infinite loop to constantly monitor network speeds.
# - Retrieves the current byte counts for both received (download) and transmitted (upload) data.
# - After waiting a specified interval, fetches the new byte counts to calculate the speed.
# - Writes the calculated speeds to a temporary file for later retrieval.
#
# Commands and Arguments:
# - `local downloaded_bytes=$(cat /sys/class/net/${interface}/statistics/rx_bytes)`: Reads the total number of bytes received
#   by the interface since the last system boot, storing the `.../rx_bytes` value in `downloaded_bytes`.
# - `local uploaded_bytes=$(cat /sys/class/net/${interface}/statistics/tx_bytes)`: Similar to `downloaded_bytes`, but for transmitted bytes `.../tx_bytes`.
# - `sleep $interval`: Pauses the loop for the duration of the specified interval, allowing time to pass for calculating speeds.
# - The process is repeated with `new_downloaded_bytes` and `new_uploaded_bytes` the old downloaded/uploaded bytes: `downloaded_bytes`
#   and `uploaded_bytes` are then subtracted from the new values to produce `downloaded_diff` and `uploaded_diff`
# - `echo -e "${AN}scale=2; $downloaded_diff / $interval / 1024 / 1024 * 8" | bc`: Calculates the download speed in Mbps, factoring 
#   in the interval. `scale=2;` gives 2 decimal places if needed. | bc sends the calculation to the calculator.
#   and converting bytes to bits (hence the multiplication by 8).
# - `echo -e "${AN}$download_speed $upload_speed" > $SPEED_FILE`: Writes the calculated download and upload speeds to `$SPEED_FILE`.
#
# Usage:
# This function should be called with two arguments: the network interface to monitor (e.g., 'eth0' or 'wlan0') and the interval
# between measurements in seconds. It runs indefinitely until the script is stopped, updating the speed file at each interval.
#
# Example:
# monitor_speed eth0 5
# This will monitor the 'eth0' interface, updating the speed file every 5 seconds.
#
# Note:
# - This function relies on the network interface's byte count files in `/sys/class/net/`, which are automatically managed by the kernel.
# - The speed calculation assumes that the network traffic can be sufficiently sampled over the specified interval for accurate measurement.

monitor_speed() {
    local interface=$1
    local interval=$2
    # Infinite loop for continuous monitoring
    while true; do
        # Obtain current received and transmitted byte counts
        local downloaded_bytes=$(cat /sys/class/net/${interface}/statistics/rx_bytes)
        local uploaded_bytes=$(cat /sys/class/net/${interface}/statistics/tx_bytes)
        sleep $interval
        # Calculate new byte counts and compute the difference
        local new_downloaded_bytes=$(cat /sys/class/net/${interface}/statistics/rx_bytes)
        local new_uploaded_bytes=$(cat /sys/class/net/${interface}/statistics/tx_bytes)
        local downloaded_diff=$((new_downloaded_bytes - downloaded_bytes))
        local uploaded_diff=$((new_uploaded_bytes - uploaded_bytes))
        # Calculate speeds in Mbps
        local download_speed=$(echo -e "${AN}scale=2; $downloaded_diff / $interval / 1024 / 1024 * 8" | bc)
        local upload_speed=$(echo -e "${AN}scale=2; $uploaded_diff / $interval / 1024 / 1024 * 8" | bc)
        

        echo -e "${AN}$download_speed $upload_speed" > $SPEED_FILE


    done
}

# Function: display_speeds 
#
# This is an example of how to simply use it - as long as you have `monitor_speed` running IN THE BACKGROUND, 
# which we will cover later. It will not be used in the main program. But while you learn you may use this as a reference.
#
# Purpose:
#
# Simple - Prints the current download and upload speeds recorded in $SPEED_FILE.
#
# Detailed - This function reads the latest network speed measurements (download and upload speeds)
# from a specified file ($SPEED_FILE) and prints them to the console. It's particularly useful
# in scripts that monitor and display network performance metrics in real-time.
#
# How it works:
# - Checks if the $SPEED_FILE exists to ensure there's data to read.
# - Reads the download and upload speeds from the $SPEED_FILE.
# - Prints the speeds to the console with appropriate labeling.
# - If $SPEED_FILE doesn't exist, prints a message indicating that speed data is not available.
#
# Commands and Arguments:
# - `if [[ -f "$SPEED_FILE" ]]`: Checks if the speed file exists.
# - `read rx_speed tx_speed < $SPEED_FILE`: Reads the download (`rx_speed`) and upload (`tx_speed`) speeds from the speed file.
# - `echo "Download speed: $rx_speed Mbps"`: Prints the download speed to the console.
# - `echo "Upload speed: $tx_speed Mbps"`: Prints the upload speed to console.
#
# Usage:
# Call this function without arguments to print the latest recorded network speeds. It's designed for use 
# in scripts that periodically display network performance metrics.
#
# Example:
# display_speeds
# This will print the latest download and upload speeds, if available, from the speed file.
#
# Note:
# This is how you will see it in the 'wild' for download(rx_bytes) and upload(tx_bytes) speed; so I left it as is to reinforce that.
# downloaded_bytes = rx_bytes = recieved bytes, tx_bytes = transferedbytes
# Play around with it! (That doesn't mean copy work and paste - actually mess with it.)
# What breaks it? How can you improve it? How can you intentionally break it and create a fix?) <------ Important questions to ask yourself.

display_speeds() {

    if [[ -f "$SPEED_FILE" ]]; then

        read rx_speed tx_speed < $SPEED_FILE
        echo "Download speed: $rx_speed Mbps"
        echo "Upload speed: $tx_speed Mbps"

    else
        echo "Speed data not available."
    fi
}

# Function: check_and_kill_duplicates
#
# Purpose:
# Simple - Terminates any other instances of this script running concurrently.
#
# Detailed - This function ensures that only one instance of this script runs at a time
# by terminating any duplicates. It prevents potential conflicts or resource contention
# issues by ensuring that no two instances perform the same operations simultaneously.
# Very useful for scripts that modify system settings or utilize network resources.
#
# How it works:
# - Retrieves the PID (Process ID) of the current script instance for exclusion.
# - Uses `pgrep` with the script's name to find all instances, filtering out the
#   current script's PID to avoid self-termination using -v to exclude the current
#   scripts PID
# - Iterates over the list of PIDs and uses `kill -9` to forcefully terminate them.
#
# Commands and Arguments:
# - `local current_pid=$$`: Captures the PID of the current script instance.
# - `local script_name=$(basename "$0")`: Extracts the name of the script file.
# - `pgrep -f "$script_name"`: Finds PIDs of processes matching the script name.
# - `grep -v "$current_pid"`: Excludes the current script's PID from the list.
# - `kill -9 $pid`: Forcefully terminates each remaining script instance.
#
# Usage:
# This function is designed to be called at the beginning of a script to ensure
# that only one instance of the script is running at any given time. It helps in
# maintaining the script's operational integrity and prevents duplicate execution.
#
# Example:
# check_and_kill_duplicates
#
# Note:
# This function is critical in environments where scripts are scheduled or may be
# inadvertently executed multiple times. It safeguards against concurrent execution
# anomalies. Where are you going to use this? What are you going to use it for?
# How could you use it to improve your script? (These are questions you should ask yourself.)

check_and_kill_duplicates() {
    # Get the PID of this script instance
    local current_pid=$$
    # Find other instances of this script running and kill them
    local script_name=$(basename "$0")
    pgrep -f "$script_name" | grep -v "$current_pid" | while read pid; do
        # echo "Terminating duplicate script instance with PID: $pid"
        kill -9 $pid
    done
}

# Function: cleanup
#
# Purpose:
# Simple - Ensures clean termination of background processes started by the script.
#
# Detailed - This function is called upon script exit to terminate any background
# processes initiated by the script, such as `monitor_speed`. It's crucial for
# preventing orphaned processes that continue running after the script has finished,
# which can lead to resource leaks or unintended operations. The function can
# be extended to include additional cleanup tasks as needed.
#
# How it works:
# - Checks if the `$monitor_speed_pid` variable is not empty, indicating that the
#   `monitor_speed` function is running in the background.
# - If a PID is found, it uses `kill` to terminate the background process, ensuring
#   that no processes started by the script are left running.
# - Additional cleanup commands can be added to extend the function's functionality.
#
# Commands and Arguments:
# - `if [[ ! -z "$monitor_speed_pid" ]]`: Checks to see if the variable containing the PID
#   of the `monitor_speed` background process is not empty.
# - `kill $monitor_speed_pid`: Sends a termination signal to the PID stored in
#   `$monitor_speed_pid`, effectively stopping the background process.
#
# Usage:
# This function should be called whenever the script exits, either normally or through
# an interrupt. It ensures that all resources used by the script are properly released.
# It is typically called using a `trap` command to catch script exit signals.
#
# Example:
#
# trap cleanup EXIT <--- will make sure your script cleans up after itself when it exits.
# additionally for this script we are monitoring a certain PID with the variable $monitor_speed_pid
# you call it like this: $monitor_speed=$! and then you can kill it like this: kill $monitor_speed
# Note:
# Implementing a cleanup function like this is a best practice for script writing,
# especially for scripts that start long-running background processes or modify system
# settings. It helps in maintaining system stability and resource management.
# No seriously, not kidding, take it from me; MAKE SURE YOU CLEAN UP all your background processes.
# It will save you a BUNCH of headache on pretty much anything you use background processes for.

cleanup() {
    if [[ ! -z "$monitor_speed_pid" ]]; then
        kill "$monitor_speed_pid" 2>/dev/null
    fi
}

# Automatically find the first active network interface
active_interface=$(find_active_interface)
echo -e "${AN}Monitoring network speed on interface: $active_interface"

# Start the speed monitor in the background
monitor_speed $active_interface 5 &
monitor_speed_pid=$! # <------ Store the PID of the background process


get_vpn_status() {
    # Use `nordvpn status` command and parse its output to extract required details
    local status=$(nordvpn status)
    # Extract each required piece of information.
    # Will comment and explain in later commits.
    local hostname=$(echo "$status" | grep 'Hostname' | awk '{print $2}')
    local ip=$(echo "$status" | grep 'IP' | awk '{print $2}')
    local country=$(echo "$status" | grep 'Country:' | cut -d':' -f2- | xargs)
    local city=$(echo "$status" | grep 'City' | cut -d':' -f2- | xargs) 
    display_dynamic $ip $hostname $city $country
}

display_dynamic() {
    local ip=$1
    local hostname=$2
    local city=$3
    local country=$4
    
    # ANSI color codes
    # will be taken out once I fully convet to global variables, I am just tired right now.
    local dark_green="\e[32m"
    local grey="\e[90m"
    local blue="\e[34m"
    local l_red="\e[94m"
    local pink="\e[95m"
    local light_green="\e[92m"
    local orange="\e[38;5;208"
    local no_color="\e[0m"
    
    # tput cup 9 0 really quick explanation: tput is a command that allows you to change the properties of the terminal.
    # cup stands for "cursor position" and it allows you to move the cursor to a specific location on the terminal.
    # The first argument is the row and the second is the column. Starting from the left top corner of the terminal.
    # Essentially we are moving the cursor to the top left corner of the terminal and down 9 rows and over 0 rows.
    # The echo command is used to print the text to the terminal.
    # The -e option is used to enable interpretation of backslash escapes.

    tput cup 9 0; echo -e "IP Address:${no_color}" " ${blue}$ip${no_color}" " | ${l_red}Hostname:${no_color}" " ${grey}$hostname${no_color}"
    tput cup 10 0; echo -e "City:" "${blue}$city${no_color}" "Country:" "${grey}$country${no_color}"
    
    
    if [[ -f "$SPEED_FILE" ]]; then
        read download_speed upload_speed < $SPEED_FILE
        tput cup 11 0; echo -e "Download: ${light_green}$download_speed Mb/s${no_color}, Upload: ${light_green}$upload_speed Mb/s${no_color}"
        tput el
    else
        tput cup 11 0; echo -e "Download: ${light_green}N/A Mb/s${no_color}, Upload: ${light_green}N/A Mb/s${no_color}"
        tput el
    fi

    if [[ $mode_1337 -eq 1 ]]; then
        tput cup 12 0; echo -e "${CYAN}1337-Roulette mode:${no_color} ${BRIGHT_GREEN}ON${no_color}"
    else
        tput cup 12 0; echo -e "${CYAN}1337-Roulette mode:${no_color} ${WHITE}OFF${no_color}"
    fi
    
    tput cup 13 0; echo -e "${BRIGHT_BLUE}Press:${no_color}${WHITE} 's' for settings.${no_color}"

}

select_country() {
    echo -e "${AN}Retrieving list of countries..."
    # The readarray command reads the output of the nordvpn groups command into an array by using the -t option and process substitution.
    # The tr command is used to remove carriage returns and hyphens from the output, ensuring a clean list of groups.
    # The awk command is used to split the output into separate lines, which are then sorted.
    # In this instance the awk command is used to split the output into separate lines, which are then sorted.
    # The 'NF' is a built-in variable in awk that contains the number of fields in the current record. <---- USEFUL TO KNOW rPath guys!
    readarray -t countries < <(nordvpn countries | tr -d '\r' | tr -d '-' | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort)
    echo -e "${AN}Please select a country by number (leave empty for random selection):"
    for i in "${!countries[@]}"; do
        echo "$((i+1))) ${countries[i]}"
    done

    read -p "Country number (RETURN for random): " country_choice
    if [ -z "$country_choice" ]; then
        # Random selection if left empty
        local random_index=$((RANDOM % ${#countries[@]}))
        selected_country=${countries[random_index]}
        echo -e "${AN}Randomly selected $selected_country."
    else
        selected_country=${countries[(country_choice-1)]} #removing the -1 will break the script and I will explain why in a later commit.
        echo -e "${AN}You selected $selected_country."    #but if you google indexing in bash you will understand why :). How do computers think?
    fi
}

# Function to retrieve and select a city from the selected country
select_city() {
    echo -e "${AN}Retrieving list of cities in $selected_country..."
    # The readarray command reads the output of the nordvpn groups command into an array by using the -t option and process substitution.
    # The tr command is used to remove carriage returns and hyphens from the output, ensuring a clean list of groups.
    # The awk command is used to split the output into separate lines, which are then sorted.
    # In this instance the awk command is used to split the output into separate lines, which are then sorted.
    # The 'NF' is a built-in variable in awk that contains the number of fields in the current record. <---- USEFUL TO KNOW rPath guys!
    readarray -t cities < <(nordvpn cities "$selected_country" | tr -d '\r' | tr -d '-' | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort)
    echo -e "${AN}Please select a city by number (leave empty for random selection):"
    for i in "${!cities[@]}"; do
        echo -e "$((i+1))) ${cities[i]}"
    done

    read -p "City number (RETURN for random): " city_choice
    if [ -z "$city_choice" ]; then
        # Random selection if left empty
        local random_index=$((RANDOM % ${#cities[@]}))
        selected_city=${cities[random_index]}
        echo -e "${AN}Randomly selected $selected_city."
    else
        selected_city=${cities[(city_choice-1)]}
        echo -e "${AN}You selected $selected_city."
    fi
}

# Select a group from the available list
select_group() {
    echo -e "${AN}Retrieving list of groups..."
    # The readarray command reads the output of the nordvpn groups command into an array by using the -t option and process substitution.
    # The tr command is used to remove carriage returns and hyphens from the output, ensuring a clean list of groups.
    # The awk command is used to split the output into separate lines, which are then sorted.
    # In this instance the awk command is used to split the output into separate lines, which are then sorted.
    # The 'NF' is a built-in variable in awk that contains the number of fields in the current record. <---- USEFUL TO KNOW rPath guys!
    readarray -t groups < <(nordvpn groups | tr -d '\r' | tr -d '-' | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort)
    echo -e "${AN}Please select a group by number (leave empty for random selection):"
    
    # The filtered list no longer includes "-", so it's safe to display and select from
    for i in "${!groups[@]}"; do
        echo "$((i+1))) ${groups[i]}"
    done

    read -p "Group number (RETURN for random): " group_choice
    if [ -z "$group_choice" ]; then
        # Random selection if left empty
        local random_index=$((RANDOM % ${#groups[@]}))
        selected_group=${groups[random_index]}
        echo -e "${AN}Randomly selected $selected_group."
    else
        # Adjusted to correctly handle zero-indexed bash arrays
        if [[ $group_choice -ge 1 && $group_choice -le ${#groups[@]} ]]; then
            local adjusted_index=$((group_choice - 1))
            selected_group=${groups[adjusted_index]}
            echo -e "${AN}You selected $selected_group."
        else
            echo -e "${AN}Invalid selection. Please try again."
            select_group # Optionally, recursively call to handle invalid input
        fi
    fi
}


# Random country and city selection
roulette_selection() {
    # Random country selection
    echo -e "$AN ${RED}${BG_BRIGHT_YELLOW}1337-Roulette${no_color} mode activated! Selecting a random country and city..."
    readarray -t countries < <(nordvpn countries | tr -d '\r' | tr -d '-' | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort)
    local random_country_index=$((RANDOM % ${#countries[@]}))
    selected_country=${countries[random_country_index]}
    echo -e "$AN ${RED}${BG_BRIGHT_YELLOW}1337-Roulette${no_color} Randomly selected country: $selected_country."

    # Random city selection within the selected country
    echo -e "$AN ${RED}${BG_BRIGHT_YELLOW}1337-Roulette${no_color} Randomly selecting a city in $selected_country..."
    readarray -t cities < <(nordvpn cities "$selected_country" | tr -d '\r' | tr -d '-' | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | sort)
    if [[ ${#cities[@]} -eq 0 ]]; then
        echo -e "$AN ${RED}${BG_BRIGHT_YELLOW}1337-Roulette${no_color} No cities available for $selected_country. Only country will be used for connection."
        selected_city=""
        mode_1337=1
    else
        local random_city_index=$((RANDOM % ${#cities[@]}))
        selected_city=${cities[random_city_index]}
        echo -e "$AN ${RED}${BG_BRIGHT_YELLOW}1337-Roulette${no_color} Randomly selected city: $selected_city."
        mode_1337=1
    fi
}

# Selection and connection
connect_vpn() {
    clear
    monitoring_active=0
    generate_output_with_color $RED

    echo "AutoNord Connection Script"
    echo "1) Select by Country"
    echo "2) Select by City (you'll select the country first)"
    echo "3) Select by Group"
    echo "4) 1337-Roulette"
    echo "5) Disconnect"
    read -p "Enter your choice or press 'Enter' to join the P2P network for torrenting: " choice

    case $choice in
        1)
            select_country
            nordvpn connect "$selected_country"
            ;;
        2)
            select_country
            select_city
            nordvpn connect "$selected_country" "$selected_city"
            ;;
        3)
            select_group
            # Assuming 'nordvpn connect group' is a valid command, replace it with the actual command if different.
            nordvpn connect "$selected_group"
            ;;
        4)
            roulette_selection
            # Assuming 'nordvpn connect' can take both country and city as arguments for random connection.
            nordvpn connect "$selected_country" "$selected_city"
            ;;
        5)
            echo "Disconnecting..."
            nordvpn disconnect
            echo "Disconnected."
            ;;

        *)
            echo "Connecting to the best server..."
            nordvpn connect
            ;;
    esac
    clear
# will change the color of the terminal header will explain in later commits.
    if [ "$mode_1337" -eq 1 ]; then
        desired_color=$CYAN
    else
        desired_color=$RED
    fi

    generate_output_with_color $desired_color

    monitoring_active=1
}

get_primary_interface() {
    # This command gets the default route, extracts the default interface
    ip route | grep default | awk '{print $5}' | head -n 1
}

# Main thread start

#GLOBAL_VARIABLES

#(old) Color Codes - will remove once I double check have the new ones in place:
ldark_green="\e[32m"
lgrey="\e[90m"
blue="\e[34m"
red="\e[31m"
lpink="\e[95m"
light_green="\e[92m"
orange="\e[38;5;208"
no_color="\e[0m"

# Normal foreground colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# Bright foreground colors
BRIGHT_BLACK="\033[1;30m"
BRIGHT_RED="\033[1;31m"
BRIGHT_GREEN="\033[1;32m"
BRIGHT_YELLOW="\033[1;33m"
BRIGHT_BLUE="\033[1;34m"
BRIGHT_MAGENTA="\033[1;35m"
BRIGHT_CYAN="\033[1;36m"
BRIGHT_WHITE="\033[1;37m"

# Normal background colors
BG_BLACK="\033[0;40m"
BG_RED="\033[0;41m"
BG_GREEN="\033[0;42m"
BG_YELLOW="\033[0;43m"
BG_BLUE="\033[0;44m"
BG_MAGENTA="\033[0;45m"
BG_CYAN="\033[0;46m"
BG_WHITE="\033[0;47m"

# Bright background colors
BG_BRIGHT_BLACK="\033[0;100m"
BG_BRIGHT_RED="\033[0;101m"
BG_BRIGHT_GREEN="\033[0;102m"
BG_BRIGHT_YELLOW="\033[0;103m"
BG_BRIGHT_BLUE="\033[0;104m"
BG_BRIGHT_MAGENTA="\033[0;105m"
BG_BRIGHT_CYAN="\033[0;106m"
BG_BRIGHT_WHITE="\033[0;107m"

# Reset color
no_color="\033[0m"
# AutoNord console pre-text
AN="${RED}AutoNord: ${no_color}"
#Stops the script from monitoring and providing output during the VPN connection and selection process
monitoring_active=0
mode_1337=0
# Check for and terminate any duplicate script instances
check_and_kill_duplicates
#clear output
clear
# Trap to ensure cleanup is performed on script exit
trap cleanup EXIT

generate_output_with_color() {
    local color=$1
    tput cup 1 0; echo -e "${color}       d8888          888            888b    888                      888${no_color}"
    tput cup 2 0; echo -e "${color}      d88888          888            8888b   888                      888${no_color}"
    tput cup 3 0; echo -e "${color}     d88P888          888            88888b  888                      888${no_color}"
    tput cup 4 0; echo -e "${color}    d88P 888 888  888 888888 .d88b.  888Y88b 888  .d88b.  888d888 .d88888${no_color}"
    tput cup 5 0; echo -e "${color}   d88P  888 888  888 888   d88  88b 888 Y88b888 d88  88b 888P   d88  888${no_color}"
    tput cup 6 0; echo -e "${color}  d88P   888 888  888 888   888  888 888  Y88888 888  888 888    888  888${no_color}"
    tput cup 7 0; echo -e "${color} d8888888888 Y88b 888 Y88b  Y88..88P 888   Y8888 Y88..88P 888    Y88b 888${no_color}"
    tput cup 8 0; echo -e "${color}d88P     888  Y88888   Y888   Y88P   888    Y888   Y888   888      Y8888P${no_color}"
}

# Find the active network interface. If none is found, exit the script with `find_active_interface`'s error message.
echo -e "Finding ${BRIGHT_GREEN}-Active-${no_color} interface to monitor."
sleep .5
active_interface=$(find_active_interface)
echo -e "$AN Monitoring network speed on ${BRIGHT_GREEN}$active_interface${no_color} continuing with start up"
echo -e "$AN "
sleep 1

connect_vpn

while true; do
    if [[ $monitoring_active -eq 1 ]]; then
        # Display connection information and speeds
        # Through `get_vpn_status`
        get_vpn_status    
    fi

    # Existing logic to handle user input
    read -t 0.1 -n 1 user_input
    if [[ $user_input == 'q' ]]; then
        echo -e "\nQuitting..."
        break  # Exit loop if 'q' is pressed
    elif [[ $user_input = s ]]; then
        clear
        echo -e "${AN}DOING ITTT!"
        connect_vpn
    fi
    
    sleep 0.5  # Adjust timing for display refresh as needed
done
# Script end logic to keep terminal active (you might not need to do anything specific here depending on how you run your script)
echo -e "${AN}Script ended. Terminal remains active for further use.