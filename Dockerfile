# Step 1: Base operating system
FROM ubuntu:22.04

# Step 2: Disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Step 3: Install required dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgis \
    wget \
    git \
    cmake \
    g++ \
    libpq-dev \
    libproj-dev \
    libgeos-dev \
    libxml2-dev \
    libbz2-dev \
    libboost-dev \
    python3 \
    python3-pip

# Step 4: Download Nominatim source code
RUN git clone https://github.com/osm-search/Nominatim.git /nominatim

# Step 5: Set working directory
WORKDIR /nominatim

# Step 6: Default command
CMD ["bash"]
