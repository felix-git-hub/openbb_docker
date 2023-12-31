FROM debian:bookworm-slim


# set version label
ARG BUILD_DATE
ARG VERSION
ARG CERTBOT_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="felix"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8



#copy file
COPY root/ /
#sudo permission

# hadolint ignore=DL3008
RUN apt-get update -q && \
    apt-get install -q -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
        build-essential\ 
        jq\
        net-tools\
        sudo\
#        curl\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
  echo "**** create abc user and make our folders ****" && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir /config && \
  mkdir /home/abc && \
  chown abc:abc /config && \
  chown abc:abc /home/abc && \
  mkdir -p /opt && \
  chown abc:abc /opt && \
  echo "abc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/abc  && \
  chmod +x /init


ENV PATH /opt/conda/bin:$PATH


# Leave these args here to better use the Docker build cache
#ARG CONDA_VERSION=py311_23.9.0-0
ARG CONDA_VERSION=latest

#user permission
WORKDIR /config
USER abc

RUN set -x && \
    whoami &&\
    UNAME_M="$(uname -m)" && \
    if [ "${UNAME_M}" = "x86_64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh"; \
        SHA256SUM="43651393236cb8bb4219dcd429b3803a60f318e5507d8d84ca00dafa0c69f1bb"; \
    elif [ "${UNAME_M}" = "s390x" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-s390x.sh"; \
        SHA256SUM="707c68e25c643c84036a16acdf836a3835ea75ffd2341c05ec2da6db1f3e9963"; \
    elif [ "${UNAME_M}" = "aarch64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-aarch64.sh"; \
        SHA256SUM="1242847b34b23353d429fcbcfb6586f0c373e63070ad7d6371c23ddbb577778a"; \
    elif [ "${UNAME_M}" = "ppc64le" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-ppc64le.sh"; \
        SHA256SUM="07b53e411c2e4423bd34c3526d6644b916c4b2143daa8fbcb36b8ead412239b9"; \
    fi  && \
    wget "${MINICONDA_URL}" -O miniconda.sh -q && \
    echo "${SHA256SUM} miniconda.sh" > shasum && \
    if [ "${CONDA_VERSION}" != "latest" ]; then sha256sum --check --status shasum; fi && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh shasum && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /config/.bashrc && \
    echo "conda activate openbb" >> /config/.bashrc && \
#    find /opt/conda/ -follow -type f -name '*.a' -delete && \
#    find /opt/conda/ -follow -type f -name '*.js.map' -delete  && \
    rm /opt/conda/pkgs/ -rf && \
    /opt/conda/condabin/conda  create -n openbb python=3.11 && \
#    openbb_version=$(curl -sSL https://api.github.com/repos/OpenBB-finance/OpenBBTerminal/releases/latest | jq -r .tag_name) && \
#    openbb_version="${openbb_version#v}"  && \
    /opt/conda/envs/openbb/bin/pip  install "openbb[all]" --no-cache-dir && \
    /opt/conda/envs/openbb/bin/pip install jupyter  && \
    /opt/conda/condabin/conda clean -afy && \
    /opt/conda/condabin/conda  clean -afy || \
    echo "fail" 

USER abc
CMD [ "/init" ]
