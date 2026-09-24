FROM dart:stable
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-25-jdk-headless gcc libc6-dev tzdata \
 && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
RUN mkdir -p /flutter/bin/cache \
 && echo 3.38.0 > /flutter/version \
 && echo '{"frameworkVersion": "3.38.0", "flutterVersion": "3.38.0", "dartSdkVersion": "3.10.0"}' > /flutter/bin/cache/flutter.version.json
ENV FLUTTER_ROOT=/flutter
COPY run.sh /run.sh
ENTRYPOINT ["sh", "/run.sh"]
