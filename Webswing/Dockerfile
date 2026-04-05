FROM eclipse-temurin:11-jdk-jammy

# ── System deps FIRST (maximizes cache reuse, independent of args) ─────────────
RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    unzip \
    xvfb \
    libxext6 libxi6 libxtst6 libxrender1 libpangoft2-1.0-0 \
 && rm -rf /var/lib/apt/lists/*

# ── Declare build args AFTER apt (cache-friendly layer order) ──────────────────
ARG WEBSWING_VERSION
ARG WEBSWING_URL

# ── Debug: verify args are populated ──────────────────────────────────────────
RUN echo "VERSION=${WEBSWING_VERSION}" && echo "URL=${WEBSWING_URL}"

# ── Download & extract Webswing (cached until ARG values change) ───────────────
RUN curl -fSL "${WEBSWING_URL}" -o /tmp/webswing.zip \
 && unzip /tmp/webswing.zip -d /opt/ \
 && ls -la /opt/ \
 && WEBSWING_DIR=$(unzip -Z1 /tmp/webswing.zip | head -1 | cut -d'/' -f1) \
 && echo "Extracted dir: ${WEBSWING_DIR}" \
 && mv /opt/${WEBSWING_DIR} /opt/webswing \
 && rm /tmp/webswing.zip

# ── Environment ────────────────────────────────────────────────────────────────
ENV WEBSWING_HOME=/opt/webswing \
    DISPLAY=:99 \
    WEBSWING_OPTS="-h 0.0.0.0 -j /opt/webswing/jetty.properties -serveradmin -pfa /opt/webswing/admin/webswing-admin.properties -adminctx /admin -aw admin/webswing-admin-server.war" \
    WEBSWING_JAVA_OPTS="-Xmx256M -Djava.net.preferIPv4Stack=true -Dwebswing.admin.url=http://localhost:8080/admin"

WORKDIR /opt/webswing

# ── Service scripts (use ENV vars, not ARG — they expand correctly at runtime) ──
RUN mkdir -p /etc/service/xvfb \
 && printf '#!/bin/sh\nexec Xvfb :99\n' > /etc/service/xvfb/run \
 && chmod +x /etc/service/xvfb/run

RUN mkdir -p /etc/service/webswing \
 && printf '#!/bin/sh\ncd $WEBSWING_HOME\nexec java $WEBSWING_JAVA_OPTS -jar $WEBSWING_HOME/server/webswing-jetty-launcher.jar -w $WEBSWING_HOME/webswing-server.war $WEBSWING_OPTS\n' \
    > /etc/service/webswing/run \
 && chmod +x /etc/service/webswing/run

RUN printf '#!/bin/sh\nrm -f /tmp/.X99-lock\n/etc/service/xvfb/run &\nsleep 1\n/etc/service/webswing/run\n' \
    > /opt/webswing/start.sh \
 && chmod +x /opt/webswing/start.sh

EXPOSE 8080
CMD ["/opt/webswing/start.sh"]