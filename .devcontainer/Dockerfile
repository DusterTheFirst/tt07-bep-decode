FROM mcr.microsoft.com/devcontainers/base:bookworm as cad_suite

ARG ARCHIVE="oss-cad-suite-linux-x64-20240316"

RUN --mount=type=bind,source=${ARCHIVE}.tgz,target=${ARCHIVE}.tgz \
    set -eux; \
    tar -xzvf ${ARCHIVE}.tgz;

RUN set -eux; \
    echo "source /oss-cad-suite/environment;" >> /home/vscode/.bashrc; \
    echo "unset VERILATOR_ROOT;" >> /home/vscode/.bashrc;

FROM cad_suite as tt_support

RUN set -eux; \
    apt update; \
    apt install -y python3-venv libcairo2-dev; \
    rm -rf /var/lib/apt/lists/*

USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN git clone -b tt07 https://github.com/TinyTapeout/tt-support-tools ~/tt

RUN set -eux; \
    python3 -m venv ~/tt/venv; \
    . ~/tt/venv/bin/activate; \
    echo "cython<3" > /tmp/constraint.txt; \
    PIP_CONSTRAINT=/tmp/constraint.txt pip install -r ~/tt/requirements.txt; \
    rm /tmp/constraint.txt; \
    echo "source ~/tt/venv/bin/activate;" >> ~/.bashrc;

FROM tt_support as openlane

ENV OPENLANE_ROOT=/home/vscode/tt/openlane \
    PDK_ROOT=/home/vscode/tt/pdk \
    PDK=sky130A \
    OPENLANE_TAG=2024.04.22
ENV OPENLANE_IMAGE_NAME=docker.io/efabless/openlane:$OPENLANE_TAG

RUN git clone --depth=1 --branch $OPENLANE_TAG https://github.com/The-OpenROAD-Project/OpenLane.git $OPENLANE_ROOT

# # Docker in Docker
# RUN set -eux; \
#     sudo apt update; \
#     sudo apt install -y ca-certificates curl; \
#     sudo install -m 0755 -d /etc/apt/keyrings; \
#     sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; \
#     sudo chmod a+r /etc/apt/keyrings/docker.asc; \
#     echo \
#         "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
#         $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#         sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
#     sudo apt update; \
#     sudo apt install -y docker-ce docker-ce-cli containerd.io; \
#     sudo rm -rf /var/lib/apt/lists/*

# Podman in Docker
RUN set -eux; \
    sudo apt update; \
    sudo apt install -y podman podman-docker; \
    sudo rm -rf /var/lib/apt/lists/*

# RUN --security=insecure \
#     set -eu; \
#     cd $OPENLANE_ROOT; \
#     make