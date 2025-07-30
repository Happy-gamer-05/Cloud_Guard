# Use a lightweight Debian base
FROM ubuntu:22.04 

# Set environment variables

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: curl, gnupg, openjdk-17, unzip, wget
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    curl \
    gnupg \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Add Elastic GPG key and repo
RUN curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor | tee /usr/share/keyrings/elasticsearch-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Logstash
RUN apt-get update && apt-get install -y logstash \
    && rm -rf /var/lib/apt/lists/*

# Install Logstash plugins
RUN /usr/share/logstash/bin/logstash-plugin install logstash-filter-geoip logstash-filter-useragent


# Copy geoip file to required location
COPY geoip/GeoLite2-City.mmdb /usr/share/logstash/GeoLite2-City.mmdb
#COPY geoip/GeoLite2-Country.mmdb /usr/share/logstash/GeoLite2-Country.mmdb
#COPY geoip/GeoLite2-ASN.mmdb /usr/share/logstash/GeoLite2-ASN.mmdb


# Copy your pipeline config (you create this file locally)
COPY pipeline/logstash.conf /usr/share/logstash/pipeline/logstash.conf

# Copy elasticsearch output config if separate (optional)
# COPY config/logstash.yml /usr/share/logstash/config/logstash.yml

# Expose beats input port (default 5044)
EXPOSE 5044

# Default command to run Logstash with your pipeline
CMD ["/usr/share/logstash/bin/logstash", "-f", "/usr/share/logstash/pipeline/logstash.conf", "--path.settings", "/usr/share/logstash/config"]
