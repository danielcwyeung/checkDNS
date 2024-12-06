#!/bin/bash

# Specific the domain, replace YOURDOMAIN with the domain you want to check
DOMAIN="YOURDOMAIN"

# Absolute paths for the scripts, replace PATH with your local path
CHECK_DNS_CNAME_SCRIPT="PATH/check_$DOMAIN.sh"
CHECK_BLOCKED_DNS_SCRIPT="PATH/blockedDNSresult$DOMAIN.sh"
BLOCKED_DNS_FILE="PATH/$DOMAIN/${DOMAIN}blockedDNS.txt"

# Run the check_websaglobalxns_com.sh script
"$CHECK_DNS_CNAME_SCRIPT"

# Check if there are any blocked DNS entries
if [[ -s "$BLOCKED_DNS_FILE" ]]; then
	echo "Blocked DNS entries found. Running blockedDNSresult$DOMAIN.sh..."
	"$CHECK_BLOCKED_DNS_SCRIPT"
else
	echo "No blocked DNS entries found. Skipping blockedDNSresult$DOMAIN.sh."
fi
