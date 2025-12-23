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
*   `TOR_MAX_CIRCUIT_DIRTINESS`: Interval in seconds to automatically rebuild Tor circuits (default: Tor default, usually 10 minutes). Set to e.g. `60` for 1 minute rotation.

### Test

```bash
curl -x http://myuser:mypassword@localhost:3128 https://httpbin.org/ip
```

## Architecture

*   **Squid**: Acts as the entry point and load balancer. It handles authentication and distributes requests to Privoxy instances in a round-robin fashion.
*   **Privoxy**: Converts HTTP requests to SOCKS5 requests for Tor.
*   **Tor**: Provides anonymity and IP rotation. Multiple instances are run to provide different exit nodes.

