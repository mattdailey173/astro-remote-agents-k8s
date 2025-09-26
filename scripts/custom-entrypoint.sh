#!/bin/bash
# Custom entrypoint script for remote execution agent

set -e

echo "Starting custom Astronomer Remote Execution Agent..."

# Set up logging
export AIRFLOW__LOGGING__LOGGING_LEVEL=${LOGGING_LEVEL:-INFO}

# Configure connections if needed
if [ -n "$DATABASE_URL" ]; then
    echo "Setting up database connection..."
    airflow connections add 'default_db' \
        --conn-type 'postgres' \
        --conn-host "${DATABASE_HOST}" \
        --conn-login "${DATABASE_USER}" \
        --conn-password "${DATABASE_PASSWORD}" \
        --conn-schema "${DATABASE_NAME}"
fi

# Initialize custom configurations
echo "Applying custom configurations..."

# Start the original agent process
exec "$@"