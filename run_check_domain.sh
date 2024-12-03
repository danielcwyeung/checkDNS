#!/bin/bash

# Run the check_weblauncher_domain.sh script
./check_domain_dns.sh

# Check if there are any blocked DNS entries
if [[ -s "blockedDNS.txt" ]]; then
	echo "Blocked DNS entries found. Running check_blocked_dns.sh..."
	./blockeddnsresult.sh
else
	echo "No blocked DNS entries found. Skipping check_blocked_dns.sh."
fi
