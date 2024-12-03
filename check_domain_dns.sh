#!/bin/bash

# Specify the domain and expected CNAME
DOMAIN="www.yahoo.com"
EXPECTED_CNAME="me-ycpi-cf-www.g06.yahoodns.net."

# Telegram Bot Token and Chat ID
TELEGRAM_BOT_TOKEN="7978130242:AAFWGtoUbZgdf8Kbl9zNYVw2ez3wkttsb28"
TELEGRAM_CHAT_ID="-4611778772"

#File containing the list of DNS servers
DNS_SERVERS_FILE="dns_servers.txt"

# Output files
FUNCTIONABLE_FILE="functionabledns.txt"
NONFUNCTIONABLE_FILE="nonfunctionabledns.txt"
PREVIOUS_NONFUNCTIONABLE_FILE="previous_nonfunctionabledns.txt"
BLOCKED_DNS_FILE="blockedDNS.txt"

# Clear previous output files
> "$FUNCTIONABLE_FILE"
> "$NONFUNCTIONABLE_FILE"
> "$BLOCKED_DNS_FILE"

# Check if the DNS servers file exists
if [[ ! -f "$DNS_SERVERS_FILE" ]]; then
	echo "DNS servers file not found: $DNS_SERVERS_FILE"
	exit 1
fi

# Count total DNS serverss
total_dns_servers=$(wc -l < "$DNS_SERVERS_FILE")

# Function to send Telegram alert
send_alert() {
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
		-d "chat_id=$TELEGRAM_CHAT_ID" \
		-d "text=$message"
}

# Function to check CNAME resolution
check_dns () {
	local dns_server="$1"
	local cname=$(nslookup "$DOMAIN" "$dns_server" 2>/dev/null | grep "canonical name" | awk '{print $5}')

	if [[ "$cname" == "$EXPECTED_CNAME" ]]; then
		echo "$dns_server" >> "$FUNCTIONABLE_FILE"
	else
		echo "$dns_server" >> "$NONFUNCTIONABLE_FILE"

		# Check if the CNAME contains the keyword ".id." - If e.g. your domain is blocked by ID, they will change your domain cname to a new cname with .id"
		if [[ "$cname" == *".id." ]]; then
			echo "$dns_server" >> "$BLOCKED_DNS_FILE"
		fi
	fi
}

# Export the function for parallel execution
export -f check_dns
export -f send_alert
export DOMAIN EXPECTED_CNAME FUNCTIONABLE_FILE NONFUNCTIONABLE_FILE TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID BLOCKED_DNS_FILE

# Read DNS servers and run checks in parallel
cat "$DNS_SERVERS_FILE" | parallel -j 0 check_dns

# Compare with previous results if they exist
if [[ -f "$PREVIOUS_NONFUNCTIONABLE_FILE" ]]; then
	current_nonfunctionable_count=$(wc -l < "$NONFUNCTIONABLE_FILE")
	previous_nonfunctionable_count=$(wc -l < "$PREVIOUS_NONFUNCTIONABLE_FILE")

	# Display counts and ratios
	echo "Current non-functionable count: $current_nonfunctionable_count out of $total_dns_servers"
	echo "Previous non-functionable count: $previous_nonfunctionable_count out of $total_dns_servers"

	# Calculate ratios
	current_ratio="$current_nonfunctionable_count/$total_dns_servers"
	previous_ratio="$previous_nonfunctionable_count/$total_dns_servers"

	echo "Current non-functionable ratio: $current_ratio"
	echo "Previous non-functionable ratio: $previous_ratio"

	# Prepare alert message
	alert_message="Current non-functionable count: $current_nonfunctionable_count out of $total_dns_servers\n\
	s	Current non-functionable ratio: $current_ratio\n\
		Previous non-functionable count: $previous_nonfunctionable_count out of $total_dns_server\n\
		Previous non-functionable ratio: $previous_ratio"

	# Check for an increase in non-functionable DNS servers
	if (( current_nonfunctionable_count > previous_nonfunctionable_count )); then
		alert_message="{Country} DNS Alert: The number of non-functionable DNS servers has increased! The domain www.yahoo.com might be blocked.\n$alert_message"
		send_alert "$alert_message"
	fi
else
	# If this is the first run, just display the current count
	current_nonfunctionable_count=$(wc -l < "$NONFUNCTIONABLE_FILE")
	echo "Current non-functionable count: $current_nonfunctionable_count out of $total_dns_servers"
	echo "Current non-functionable ratio: $current_nonfunctionable_count/$total_dns_servers"

	# Prepare alert message for the first run
	alert_message="IDDNS: Current non-functionable count: $current_nonfunctionable_count out of $total_dns_servers\n\
		Current non-functionable ratio: $current_nonfunctionable_count/$total_dns_servers"
	send_alert "$alert_message"
fi

# Check if there are any blocked DNS entries and send alert
if [[ -s "$BLOCKED_DNS_FILE" ]]; then
	blocked_count=$(wc -l < "$BLOCKED_DNS_FILE")
	blocked_alert_message="{Country} DNS Alert: There are $blocked_count blocked DNS servers for the domain www.yahoo.com listed in blockedDNS.txt."
	send_alert "$blocked_alert_message"
fi

# Save the current non-functionable results for the next run
mv "$NONFUNCTIONABLE_FILE" "$PREVIOUS_NONFUNCTIONABLE_FILE"

echo "DNS resolution checks complete."
