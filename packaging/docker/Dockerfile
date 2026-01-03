# DevOps Toolkit - Development and Testing Container
FROM ubuntu:22.04

LABEL maintainer="John Sabba <johnsabba@example.com>"
LABEL description="DevOps Toolkit - Collection of development and deployment scripts"
LABEL version="1.0.0"

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    php-cli \
    php-curl \
    php-zip \
    nodejs \
    npm \
    docker.io \
    dpkg-dev \
    build-essential \
    rpm \
    && rm -rf /var/lib/apt/lists/*

# Install Composer (for PHP projects)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create working directory
WORKDIR /opt/devops-toolkit

# Copy source files
COPY . /opt/devops-toolkit/

# Set permissions
RUN chmod +x /opt/devops-toolkit/devops-toolkit/bin/scripts/*.sh \
    && chmod +x /opt/devops-toolkit/*.sh \
    && chmod +x /opt/devops-toolkit/version.sh \
    && chmod +x /opt/devops-toolkit/tests/test-scripts.sh

# Create symlinks for easy access
RUN ln -sf /opt/devops-toolkit/devops-toolkit/bin/scripts/django-project-creator-v3.sh /usr/local/bin/django-creator \
    && ln -sf /opt/devops-toolkit/devops-toolkit/bin/scripts/php-switcher.sh /usr/local/bin/php-switcher \
    && ln -sf /opt/devops-toolkit/devops-toolkit/bin/scripts/download-manager.sh /usr/local/bin/download-manager \
    && ln -sf /opt/devops-toolkit/devops-toolkit/bin/scripts/laravel-start.sh /usr/local/bin/laravel-start \
    && ln -sf /opt/devops-toolkit/version.sh /usr/local/bin/devops-version

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Create entry point script
RUN echo '#!/bin/bash\n\
echo "=== DevOps Toolkit Development Container ==="\n\
echo "Available commands:"\n\
echo "  django-creator   - Create Django projects"\n\
echo "  php-switcher     - Switch PHP versions"\n\
echo "  download-manager - Download manager utility"\n\
echo "  laravel-start    - Laravel project starter"\n\
echo "  devops-version   - Version management"\n\
echo ""\n\
echo "Build commands:"\n\
echo "  make help        - Show build system help"\n\
echo "  make test        - Run test suite"\n\
echo "  make deb         - Build Debian package"\n\
echo ""\n\
echo "Working directory: $(pwd)"\n\
echo "========================================"\n\
echo ""\n\
exec "$@"\n' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bash -c "django-creator --help > /dev/null 2>&1 || exit 1"

# Set the default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]