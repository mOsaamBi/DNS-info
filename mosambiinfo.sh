#!/bin/bash

# Check if a domain was provided
if [ -z "$1" ]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

DOMAIN=$1
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="results_$DOMAIN_$DATE"
mkdir -p $OUTPUT_DIR

# Function to gather subdomains using assetfinder
gather_assetfinder() {
    echo "[*] Gathering subdomains with Assetfinder..."
    assetfinder --subs-only $DOMAIN | tee $OUTPUT_DIR/assetfinder_subdomains.txt
    echo "[*] Assetfinder results saved in $OUTPUT_DIR/assetfinder_subdomains.txt"
}

# Function to gather subdomains using subfinder
gather_subfinder() {
    echo "[*] Gathering subdomains with Subfinder..."
    subfinder -d $DOMAIN -silent | tee $OUTPUT_DIR/subfinder_subdomains.txt
    echo "[*] Subfinder results saved in $OUTPUT_DIR/subfinder_subdomains.txt"
}

# Function to perform DNS reconnaissance with dnsrecon
dns_recon() {
    echo "[*] Performing DNS reconnaissance with DNSRecon..."
    dnsrecon -d $DOMAIN | tee $OUTPUT_DIR/dnsrecon_output.txt
    echo "[*] DNSRecon results saved in $OUTPUT_DIR/dnsrecon_output.txt"
}

# Function to combine results and remove duplicates
combine_results() {
    echo "[*] Combining and removing duplicate subdomains..."
    cat $OUTPUT_DIR/assetfinder_subdomains.txt $OUTPUT_DIR/subfinder_subdomains.txt | sort -u | tee $OUTPUT_DIR/unique_subdomains.txt
    echo "[*] Unique subdomains saved in $OUTPUT_DIR/unique_subdomains.txt"
}

# Function to check DNS resolution of discovered subdomains
check_dns_resolution() {
    echo "[*] Checking DNS resolution of subdomains..."
    while read subdomain; do
        if host "$subdomain" &> /dev/null; then
            echo "$subdomain resolves"
            echo "$subdomain" >> $OUTPUT_DIR/resolving_subdomains.txt
        else
            echo "$subdomain does not resolve"
        fi
    done < $OUTPUT_DIR/unique_subdomains.txt
    echo "[*] Resolving subdomains saved in $OUTPUT_DIR/resolving_subdomains.txt"
}

# Run the script functions
gather_assetfinder
gather_subfinder
dns_recon
combine_results
check_dns_resolution

echo "[*] Task completed. Final results are stored in the $OUTPUT_DIR directory."
