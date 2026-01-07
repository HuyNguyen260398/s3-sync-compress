FROM nginx:alpine

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    bash \
    curl \
    jq \
    && ln -sf python3 /usr/bin/python

# Create virtual environment and install Python packages
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir boto3 awscli fastapi uvicorn

# Make virtual environment available globally
ENV PATH="/opt/venv/bin:$PATH"

# Create application directories
RUN mkdir -p /app/data /app/output /app/scripts

# Copy application files
COPY aws_s3_sync_compress.py /app/scripts/
COPY index.html /index.html
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /app/scripts/

# Make scripts executable
RUN chmod +x /app/scripts/entrypoint.sh

# Create nginx user directories and set permissions
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx \
    && chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx /app \
    && chmod -R 755 /app \
    && chmod -R 777 /app/output

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Use custom entrypoint that runs both the sync service and nginx
CMD ["/app/scripts/entrypoint.sh"]