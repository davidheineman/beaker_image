#!/bin/bash

# SLOW: Copy env variables from docker process (such as HF_TOKEN)
# process_info=$(ps -e -o user,pid,cmd | grep "/usr/sbin/sshd -D" | grep "^root")
# pids=$(echo "$process_info" | awk '{print $2}')
# for pid in $pids; do
#     env_vars=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n')
#     for env_var in $env_vars; do
#         key=$(echo "$env_var" | cut -d= -f1)
#         value=$(echo "$env_var" | cut -d= -f2-)
#         if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
#             if [ -z "${!key}" ]; then
#                 export "$env_var"
#             fi
#         fi
#     done
# done

# Copy env vars from Beaker process
if [ ! -f /root/.ssh/environment ]; then
    if [ -r /proc/1/environ ]; then
        env_vars=$(cat /proc/1/environ 2>/dev/null | tr "\0" "\n")
        for env_var in $env_vars; do
            key=$(echo "$env_var" | cut -d= -f1)
            value=$(echo "$env_var" | cut -d= -f2-)
            if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                if [ -z "${!key}" ]; then
                    export "$env_var"
                fi
            fi
        done
    fi
    printenv > /root/.ssh/environment
fi

# Start OpenSSH server
exec /usr/sbin/sshd -D
