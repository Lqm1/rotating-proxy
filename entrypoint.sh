#!/bin/bash
set -e

# Configuration
TOR_INSTANCES=${TORS:-10}
SQUID_PORT=3128
SQUID_USER=${PROXY_USER:-admin}
SQUID_PASSWORD=${PROXY_PASSWORD:-password}

echo "Setting up Rotating Proxy with $TOR_INSTANCES instances..."

# Setup Squid Authentication
htpasswd -bc /etc/squid/passwd "$SQUID_USER" "$SQUID_PASSWORD"

# Base Ports
TOR_BASE_PORT=9050
PRIVOXY_BASE_PORT=8118

# Prepare Directories
mkdir -p /var/lib/tor_instances
mkdir -p /etc/privoxy_instances
chown -R tor /var/lib/tor_instances

# Initialize Squid Config
cat <<EOF > /etc/squid/squid.conf
http_port $SQUID_PORT
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Rotating Proxy
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
never_direct allow all
# Disable cache
cache deny all
EOF

# Loop to create and start instances
for i in $(seq 1 $TOR_INSTANCES); do
    TOR_PORT=$((TOR_BASE_PORT + i - 1))
    PRIVOXY_PORT=$((PRIVOXY_BASE_PORT + i - 1))
    
    echo "Starting Instance $i: Tor($TOR_PORT) -> Privoxy($PRIVOXY_PORT)"

    # --- Tor Setup ---
    TOR_DIR="/var/lib/tor_instances/$i"
    mkdir -p "$TOR_DIR"
    chmod 700 "$TOR_DIR"
    chown tor "$TOR_DIR"
    
    TORRC="$TOR_DIR/torrc"
    echo "SocksPort $TOR_PORT" > "$TORRC"
    echo "DataDirectory $TOR_DIR" >> "$TORRC"
    
    # Run Tor as 'tor' user in background
    su -s /bin/sh tor -c "tor -f $TORRC > /dev/null" &
    
    # --- Privoxy Setup ---
    PRIVOXY_CONF="/etc/privoxy_instances/config_$i"
    
    # Create minimal Privoxy config
    cat <<EOF_PRIVOXY > "$PRIVOXY_CONF"
confdir /etc/privoxy
logdir /var/log/privoxy
listen-address 127.0.0.1:$PRIVOXY_PORT
forward-socks5t / 127.0.0.1:$TOR_PORT .
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
forwarded-connect-retries 0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
EOF_PRIVOXY

    # Run Privoxy in background
    # Ensure log directory exists and is writable
    mkdir -p /var/log/privoxy
    chown -R privoxy:privoxy /var/log/privoxy
    
    su -s /bin/sh privoxy -c "privoxy --no-daemon $PRIVOXY_CONF > /dev/null" &
    
    # --- Squid Setup ---
    echo "cache_peer 127.0.0.1 parent $PRIVOXY_PORT 0 no-query no-digest round-robin name=proxy$i" >> /etc/squid/squid.conf
done

# Wait for services to settle
sleep 5

echo "Starting Squid on port $SQUID_PORT..."
# Run Squid in foreground
squid -N -d 1
