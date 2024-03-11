#!/bin/bash

# check if duration argument is provided
if [ -z "$1" ]; then
    echo "Error: Duration argument is missing."
    echo "Usage: $0 <duration in seconds> [cron]"
    exit 1
fi

# check if duration argument is a valid positive integer
duration=$1
if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
    echo "Error: Duration argument must be a positive integer."
    echo "Usage: $0 <duration in seconds> [cron]"
    exit 1
fi

# save the cronjob_flag
cronjob_flag=$2

# function to check processes and move them to background
function check_and_move_to_background {

    # extract the name of the current script
    script_name=$(basename "$0")

    # get a list of processes started via command line
    processes=$(ps -eo pid,tty,cmd | awk '$2 ~ /^pts\// && $3 != "/bin/bash" {print $1}')

    for pid in $processes; do
        # check if the process still exists
        if [[ "$pid" =~ ^[0-9]+$ ]] && ps -p "$pid" > /dev/null && ! grep -q "$script_name" "/proc/$pid/cmdline"; then
            # get the start time of the process in seconds
            start_time=$(ps -o etimes= -p "$pid")

            # check if the start time of the process is greater than the specified duration
            if [[ "$start_time" -gt "$duration" ]]; then

                # move the process to background
                kill -STOP "$pid"
                sleep 0.0001
                kill -CONT "$pid"
                echo "Process $pid was has been running for longer than ${duration} seconds. Moved to background"

            fi

        fi

    done

}

# check if the script is started by a cron job
if [[ "$cronjob_flag" == "cron" ]]; then
    check_and_move_to_background
    exit 0
fi

# infinite loop to check processes every specified duration
while true; do

    check_and_move_to_background

    # if not started by cron job, wait before checking processes again
    sleep 120

done
