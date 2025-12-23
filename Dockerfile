FROM alpine:latest

# Install dependencies
RUN apk add --no-cache squid privoxy tor apache2-utils bash

# Create directory for scripts
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose Squid port
EXPOSE 3128

# Start the container
ENTRYPOINT ["/app/entrypoint.sh"]
