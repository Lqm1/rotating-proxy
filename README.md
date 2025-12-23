# Docker Rotating Proxy

A rotating proxy server using Squid, Privoxy, and Tor.

```
               Docker Container
               -------------------------------------------------------
                        <-> Privoxy 1 <-> Tor Proxy 1
Client <---->  Squid    <-> Privoxy 2 <-> Tor Proxy 2
                        <-> Privoxy n <-> Tor Proxy n
```

**Why:** Lots of IP addresses. One single endpoint for your client. Load-balancing by Squid.

## Usage

### Build

```bash
docker build -t rotating-proxy .
```

### Run

```bash
docker run -d -p 3128:3128 -e TORS=10 -e PROXY_USER=myuser -e PROXY_PASSWORD=mypassword rotating-proxy
```

### Environment Variables

*   `TORS`: Number of Tor instances to run (default: 10).
*   `PROXY_USER`: Username for Squid authentication (default: admin).
*   `PROXY_PASSWORD`: Password for Squid authentication (default: password).
*   `TOR_MAX_CIRCUIT_DIRTINESS`: Interval in seconds to automatically rebuild Tor circuits (default: 600 seconds, Tor's default of 10 minutes). Set to e.g. `60` for 1 minute rotation.
*   `TOR_NEW_CIRCUIT_PERIOD`: Period in seconds to consider creating a new circuit (default: 30).
*   `TOR_EXIT_NODES`: Comma separated list of exit nodes or country codes (e.g. `{us},{jp}`).
*   `TOR_ENTRY_NODES`: Comma separated list of entry nodes or country codes (e.g. `{us}`).
*   `TOR_STRICT_NODES`: Set to `1` to force Tor to use only the configured ExitNodes (default: 0).
*   `TOR_EXCLUDE_EXIT_NODES`: Comma separated list of exit nodes or country codes to exclude (e.g. `{ru},{cn}`).
*   `TOR_EXCLUDE_NODES`: Comma separated list of nodes or country codes to exclude from ANY position in the circuit.
*   `TOR_GEOIP_EXCLUDE_UNKNOWN`: Set to `1` to exclude nodes with unknown country codes (default: auto).
*   `TOR_USE_ENTRY_GUARDS`: Set to `1` to use Entry Guards (default: 1).
*   `TOR_NUM_ENTRY_GUARDS`: Number of Entry Guards to use (default: auto).
*   `TOR_BANDWIDTH_RATE`: Maximum bandwidth rate (e.g. `5 MBits`).
*   `TOR_BANDWIDTH_BURST`: Maximum bandwidth burst (e.g. `10 MBits`).
*   `TOR_CONN_LIMIT`: Minimum number of file descriptors to limit to (e.g. `100`).

### Test

```bash
curl -x http://myuser:mypassword@localhost:3128 https://httpbin.org/ip
```

## Architecture

*   **Squid**: Acts as the entry point and load balancer. It handles authentication and distributes requests to Privoxy instances in a round-robin fashion.
*   **Privoxy**: Converts HTTP requests to SOCKS5 requests for Tor.
*   **Tor**: Provides anonymity and IP rotation. Multiple instances are run to provide different exit nodes.

