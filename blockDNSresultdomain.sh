#!/bin/bash

# Specific the domain to lookup
DOMAIN="YOURDOMAIN"
DOMAINNAME="YOURDOMAINNAME"
EXPECTED_CNAME="EXPECTEDCNAME."

# File containing the blocked DNS servers
BLOCKED_DNS_FILE="PATH/$DOMAINNAME/${DOMAINNAME}blockedDNS.txt"
RESULTS_FILE="PATH/$DOMAINNAME/${DOMAINNAME}blocked_dns_results.txt"

# Telegram Bot Token and Chat ID
TELEGRAM_BOT_TOKEN="TELEBOTTOKEN"
TELEGRAM_CHAT_ID="TELECHATID"

# Function to send Telegram alert
send_alert() {
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
		-d "chat_id=$TELEGRAM_CHAT_ID" \
		-d "text=$message" \
		-d "parse_mode=Markdown"
}

# Clear previous results file
> "$RESULTS_FILE"

# Check if the blocked DNS file exists
if [[ ! -f "$BLOCKED_DNS_FILE" ]]; then
    echo "Blocked DNS file not found: $BLOCKED_DNS_FILE"
    exit 1
fi

# Function to check CNAME resolution for blocked DNS servers
check_blocked_dns() {
    local dns_server="$1"
    local cname=$(nslookup "$DOMAIN" "$dns_server" 2>/dev/null | grep "canonical name" | awk '{print $5}')

    if [[ -z "$cname" ]]; then
        echo "$dns_server: No CNAME record found." >> "$RESULTS_FILE"
    else
        echo "$dns_server: CNAME is $cname" >> "$RESULTS_FILE"
    fi
}

# Read blocked DNS servers and run checks in parallel
while read -r dns_server; do
    check_blocked_dns "$dns_server"
done < "$BLOCKED_DNS_FILE"

# Send alert with the contents of the results file
if [[ -s "$RESULTS_FILE" ]]; then
	results_content=$(<"$RESULTS_FILE")
	send_alert "${DOMAIN}CNAME check results for blocked DNS servers (expected CNAME is ${EXPECTED_CNAME}):\n\n\`\`\`\n$results_content\n\`\`\`"
else
	send_alert "No CNAME records found for the blocked DNS servers."
fi

echo "CNAME checks for blocked DNS servers complete. Results saved in $RESULTS_FILE."
