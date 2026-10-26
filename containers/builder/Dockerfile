ARG EMSCRIPTEN_IMAGE=emscripten/emsdk:3.1.14@sha256:4c3e0a0dac61430b719e82118ae9b2c7480902a2713267e80fa296d39f7ab921

FROM ${EMSCRIPTEN_IMAGE} AS qt-builder

ARG CMAKE_VERSION=3.28.3
ARG QT_VERSION=6.4.2
ARG QT_ARCHIVE=qt-everywhere-src-6.4.2.tar.xz
ARG QT_ARCHIVE_URL=https://download.qt.io/archive/qt/6.4/6.4.2/single/qt-everywhere-src-6.4.2.tar.xz
ARG QT_ARCHIVE_SHA256=689f53e6652da82fccf7c2ab58066787487339f28d1ec66a8765ad357f4976be

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        curl \
        flex \
        fonts-freefont-ttf \
        gperf \
        libatspi2.0-dev \
        libdbus-1-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libgl1-mesa-dev \
        libglib2.0-dev \
        libice-dev \
        libinput-dev \
        libjpeg-dev \
        libmtdev-dev \
        libpng-dev \
        libsm-dev \
        libssl-dev \
        libx11-dev \
        libx11-xcb-dev \
        libxcb-cursor-dev \
        libxcb-glx0-dev \
        libxcb-icccm4-dev \
        libxcb-image0-dev \
        libxcb-keysyms1-dev \
        libxcb-randr0-dev \
        libxcb-render-util0-dev \
        libxcb-shape0-dev \
        libxcb-shm0-dev \
        libxcb-sync-dev \
        libxcb-util-dev \
        libxcb-xfixes0-dev \
        libxcb1-dev \
        libxext-dev \
        libxfixes-dev \
        libxi-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libxrender-dev \
        ninja-build \
        perl \
        pkg-config \
        python3-pip \
        xz-utils \
        zlib1g-dev \
    && python3 -m pip install --no-cache-dir "cmake==${CMAKE_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/src

RUN curl --fail --location --retry 5 \
        --output "${QT_ARCHIVE}" "${QT_ARCHIVE_URL}" \
    && echo "${QT_ARCHIVE_SHA256}  ${QT_ARCHIVE}" | sha256sum --check - \
    && tar --extract --file "${QT_ARCHIVE}" \
    && rm "${QT_ARCHIVE}"

RUN mkdir -p /opt/build/qt-host \
    && cd /opt/build/qt-host \
    && "/opt/src/qt-everywhere-src-${QT_VERSION}/configure" \
        -prefix "/opt/qt/${QT_VERSION}/host" \
        -release \
        -opensource \
        -confirm-license \
        -nomake examples \
        -nomake tests \
        -submodules qtbase,qtdeclarative,qtimageformats,qtsvg,qtscxml \
    && cmake --build . --parallel "$(nproc)" \
    && cmake --install .

RUN source /emsdk/emsdk_env.sh \
    && mkdir -p /opt/build/qt-wasm-threaded \
    && cd /opt/build/qt-wasm-threaded \
    && "/opt/src/qt-everywhere-src-${QT_VERSION}/configure" \
        -qt-host-path "/opt/qt/${QT_VERSION}/host" \
        -platform wasm-emscripten \
        -prefix "/opt/qt/${QT_VERSION}/wasm-threaded" \
        -release \
        -opensource \
        -confirm-license \
        -feature-thread \
        -nomake examples \
        -nomake tests \
        -submodules qtbase,qtdeclarative,qtimageformats,qtsvg,qtscxml \
    && cmake --build . --parallel "$(nproc)" \
    && cmake --install .

COPY cmake/CollectQtLicenses.cmake /opt/build/CollectQtLicenses.cmake

RUN cmake \
    "-DKS_QT_SOURCE_ROOT=/opt/src/qt-everywhere-src-${QT_VERSION}" \
    "-DKS_QT_LICENSE_DIR=/opt/qt/${QT_VERSION}/wasm-threaded/licenses" \
    "-DKS_QT_VERSION=${QT_VERSION}" \
    -P /opt/build/CollectQtLicenses.cmake

FROM ${EMSCRIPTEN_IMAGE} AS builder

ARG CMAKE_VERSION=3.28.3
ARG QT_VERSION=6.4.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        brotli \
        build-essential \
        ca-certificates \
        fontconfig \
        fonts-freefont-ttf \
        git \
        gzip \
        libegl1 \
        libfontconfig1 \
        libfreetype6 \
        libgl1 \
        libglib2.0-0 \
        libopengl0 \
        libpcre2-16-0 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxext6 \
        libxkbcommon0 \
        linux-libc-dev \
        make \
        ninja-build \
        perl \
        pkg-config \
        python3-pip \
        xz-utils \
    && python3 -m pip install --no-cache-dir "cmake==${CMAKE_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

COPY --from=qt-builder /opt/qt /opt/qt
COPY containers/builder/entrypoint.sh /usr/local/bin/kernelshark-wasm-entrypoint

RUN chmod 0755 /usr/local/bin/kernelshark-wasm-entrypoint

ENV EMSDK=/emsdk
ENV QT_HOST_PATH=/opt/qt/${QT_VERSION}/host
ENV QT_WASM=/opt/qt/${QT_VERSION}/wasm-threaded

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/kernelshark-wasm-entrypoint"]
CMD ["bash"]
