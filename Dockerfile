FROM ubuntu:16.04

ENV SYNTAXNETDIR=/opt/tensorflow PATH=$PATH:/root/bin

# Install system packages. This doesn't include everything the TensorFlow
# dockerfile specifies, so if anything goes awry, maybe install more packages
# from there. Also, running apt-get clean before further commands will make the
# Docker images smaller.
RUN mkdir -p $SYNTAXNETDIR \
    && cd $SYNTAXNETDIR \
    && apt-get update \
    && apt-get install -y \
          file \
          git \
          graphviz \
          libcurl3-dev \
          libfreetype6-dev \
          libgraphviz-dev \
          liblapack-dev \
          libopenblas-dev \
          libpng-dev \
          libxft-dev \
          openjdk-8-jdk \
          python-dev \
          python-mock \
          python-pip \
          python2.7 \
          swig \
          unzip \
          vim \
          wget \
          zlib1g-dev \
    && apt-get clean \
    && (rm -f /var/cache/apt/archives/*.deb \
        /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true)

# Install common Python dependencies. Similar to above, remove caches
# afterwards to help keep Docker images smaller.
RUN pip install --ignore-installed pip \
    && python -m pip install numpy \
    && rm -rf /root/.cache/pip /tmp/pip*
RUN python -m pip install \
          asciitree \
          ipykernel \
          jupyter \
          matplotlib \
          pandas \
          protobuf \
          scipy \
          sklearn \
    && python -m ipykernel.kernelspec \
    && python -m pip install pygraphviz \
          --install-option="--include-path=/usr/include/graphviz" \
          --install-option="--library-path=/usr/lib/graphviz/" \
    && python -m jupyter_core.command nbextension enable \
          --py --sys-prefix widgetsnbextension \
    && rm -rf /root/.cache/pip /tmp/pip*

# Installs Bazel.
#RUN wget --quiet https://github.com/bazelbuild/bazel/releases/download/0.8.1/bazel-0.8.1-installer-linux-x86_64.sh \
#    && chmod +x bazel-0.8.1-installer-linux-x86_64.sh \
#    && ./bazel-0.8.1-installer-linux-x86_64.sh \
#    && rm ./bazel-0.8.1-installer-linux-x86_64.sh

# Install Bazel from source
ARG BAZEL_VER=0.5.4
ENV BAZEL_VER $BAZEL_VER
ENV BAZEL_INSTALLER bazel-$BAZEL_VER-installer-linux-x86_64.sh
ENV BAZEL_URL https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VER/$BAZEL_INSTALLER
RUN wget $BAZEL_URL \
    && chmod +x $BAZEL_INSTALLER \
    && ./$BAZEL_INSTALLER \
    && rm ./$BAZEL_INSTALLER

COPY WORKSPACE $SYNTAXNETDIR/syntaxnet/WORKSPACE
#ADD https://github.com/tensorflow/tensorflow/archive/v1.0.0.tar.gz /tmp/tensorflow-1.0.0.tar.gz
#RUN tar -xzf /tmp/tensorflow-1.0.0.tar.gz
#RUN chmod +x /tmp/tensorflow-1* \
#    && mv /tmp/tensorflow-1*/* $SYNTAXNETDIR/syntaxnet/tensorflow
#RUN mkdir /build && tar -C build -xzf /tmp/tensorflow-1.0.0.tar.gz && /bin/rm /tmp/tensorflow-1.0.0.tar.gz


COPY tensorflow $SYNTAXNETDIR/syntaxnet/tensorflow

# Compile common TensorFlow targets, which don't depend on DRAGNN / SyntaxNet
# source. This makes it more convenient to re-compile DRAGNN / SyntaxNet for
# development (though not as convenient as the docker-devel scripts).
RUN cd $SYNTAXNETDIR/syntaxnet/tensorflow \
    && tensorflow/tools/ci_build/builds/configured CPU \
    && cd $SYNTAXNETDIR/syntaxnet \
    && bazel build -c opt @org_tensorflow//tensorflow:tensorflow_py

