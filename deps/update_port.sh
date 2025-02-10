#!/bin/bash

if ! command -v beaker &> /dev/null; then
    echo "beaker not found"
    exit 1
fi

BD_OUT=$(beaker session describe ${1:+$1})
HOST_NAME=$(echo "$BD_OUT" | grep -o '[^[:space:]]*\.reviz\.ai2\.in' | head -n 1)

if [ -z "$BD_OUT" ]; then
    return 1
fi

# Get all port mappings
autoload -U colors && colors
echo "Mapping ports for host: $fg[magenta]$HOST_NAME$reset_color"
echo "$BD_OUT" | awk -F'->' '/\.ai2\.in/ {
    split($1, a, ":")
    split($2, b, "/")
    print "Port: " a[2] " (remote) -> " b[1] " (local)"
}'

# Get the port which maps to 8080 (openssh)
server_port=$(echo "$BD_OUT" | awk -F'->' '/\.ai2\.in/ {
    split($1, a, ":")
    split($2, b, "/")
    if (b[1] == 8080) {
        print a[2]
    }
}')
jupyter_port=$(echo "$BD_OUT" | awk -F'->' '/\.ai2\.in/ {
    split($1, a, ":")
    split($2, b, "/")
    if (b[1] == 8888) {
        print a[2]
    }
}')
custom_port0=$(echo "$BD_OUT" | awk -F'->' '/\.ai2\.in/ {
    split($1, a, ":")
    split($2, b, "/")
    if (b[1] == 8000) {
        print a[2]
    }
}')
custom_port1=$(echo "$BD_OUT" | awk -F'->' '/\.ai2\.in/ {
    split($1, a, ":")
    split($2, b, "/")
    if (b[1] == 8001) {
        print a[2]
    }
}')

sed -i '' "/^Host ai2$/,/^$/s/^[[:space:]]*Hostname.*$/    Hostname $HOST_NAME/" ~/.ssh/config

# Replace the Port line in ~/.ssh/config for Host ai2 with the new local_port
hosts=("ai2" "ai2-01" "ai2-20" "ai2-50" "ai2-51" "ai2-230" "ai2-231" "ai2-232" "ai2-233" "ai2-234" "ai2-235" "ai2-236" "ai2-237" "ai2-238" "ai2-239" "ai2-240" "ai2-241" "ai2-242" "ai2-243" "ai2-244" "ai2-245" "ai2-246" "ai2-247" "ai2-248" "ai2-249" "ai2-250" "ai2-251" "ai2-252" "ai2-253" "ai2-254" "ai2-255" "ai2-102" "ai2-103" "ai2-104" "ai2-105" "ai2-106" "ai2-107" "ai2-108" "ai2-109" "ai2-110" "ai2-111" "ai2-112" "ai2-113" "ai2-114" "ai2-115" "ai2-116" "ai2-117" "ai2-118" "ai2-119" "ai2-120" "ai2-121" "ai2-122" "ai2-123" "ai2-124" "ai2-125" "ai2-126" "ai2-127" "ai2-128" "ai2-129" "ai2-130" "ai2-131" "ai2-132" "ai2-133" "ai2-134" "ai2-135" "ai2-136" "ai2-137" "ai2-138" "ai2-139" "ai2-140" "ai2-141" "ai2-142" "ai2-143" "ai2-144" "ai2-145" "ai2-146" "ai2-147" "ai2-148" "ai2-149" "ai2-150" "ai2-151" "ai2-152" "ai2-153" "ai2-154" "ai2-155" "ai2-156" "ai2-157" "ai2-158" "ai2-159" "ai2-160" "ai2-161" "ai2-162" "ai2-163" "ai2-164" "ai2-165" "ai2-166" "ai2-167" "ai2-168" "ai2-169" "ai2-170" "ai2-171" "ai2-172" "ai2-173" "ai2-174" "ai2-175" "ai2-176" "ai2-177" "ai2-178" "ai2-179" "ai2-180" "ai2-181" "ai2-182" "ai2-183" "ai2-184" "ai2-185" "ai2-186" "ai2-187" "ai2-188" "ai2-189" "ai2-190" "ai2-191" "ai2-192" "ai2-193" "ai2-194" "ai2-195" "ai2-196" "ai2-197" "ai2-198" "ai2-200" "ai2-201" "ai2-202" "ai2-203" "ai2-204" "ai2-205" "ai2-206" "ai2-207" "ai2-208" "ai2-209" "ai2-210" "ai2-211" "ai2-212" "ai2-213" "ai2-214" "ai2-215" "ai2-216" "ai2-217" "ai2-218" "ai2-219" "ai2-220" "ai2-221" "ai2-222" "ai2-223" "ai2-224" "ai2-225" "ai2-226" "ai2-227" "ai2-228" "ai2-229" "ai2-435" "ai2-436" "ai2-437" "ai2-256" "ai2-257" "ai2-258" "ai2-259" "ai2-260" "ai2-261" "ai2-262" "ai2-263" "ai2-264" "ai2-265" "ai2-266" "ai2-267" "ai2-268" "ai2-269" "ai2-273" "ai2-274" "ai2-41" "ai2-42")
echo "Updated SSH port to $fg[magenta]$HOST_NAME$reset_color:$fg[red]$server_port$reset_color in ~/.ssh/config for all ai2 hosts."
for host_alias in "${hosts[@]}"; do
    if [ -n "$server_port" ]; then
        sed -i.bak '/^Host '"$host_alias"'$/,/^$/s/^    Port .*/    Port '"$server_port"'/' ~/.ssh/config
        # echo "Updated SSH port $server_port in ~/.ssh/config for Host $host."
    else
        echo "No mapping found for remote port 8080 on host $host_alias. See ~/.ssh/config."
    fi
done

# Forward local ports remote ports (-f = silent)
# pkill -f 'ssh -L 8000:127.0.0.1:8000'
# ssh -L 8000:127.0.0.1:8000 -N -f root@ai2
# ssh -L 8001:127.0.0.1:8001 -N -f root@ai2
# ssh -L 8888:127.0.0.1:8888 -N -f root@ai2