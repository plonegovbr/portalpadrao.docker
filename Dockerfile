FROM python:2.7-slim-stretch as base

ENV PIP=9.0.3 \
    ZC_BUILDOUT=2.13.1 \
    SETUPTOOLS=38.7.0 \
    WHEEL=0.33.1 \
    PLONE_MAJOR=4.3 \
    PLONE_VERSION=4.3.3 \
    PLONE_MD5=0fbf96851d5d1c08967e980343482999

RUN useradd --system -m -d /plone -U -u 500 plone \
    && mkdir -p /plone/instance/ /data/filestorage /data/blobstorage

FROM base as builder

RUN buildDeps="dpkg-dev gcc libbz2-dev libc6-dev libjpeg62-turbo-dev libopenjp2-7-dev libpcre3-dev libssl-dev libtiff5-dev libxml2-dev libxslt1-dev wget zlib1g-dev" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $buildDeps \
 && wget -O Plone.tgz https://launchpad.net/plone/$PLONE_MAJOR/$PLONE_VERSION/+download/Plone-$PLONE_VERSION-UnifiedInstaller.tgz \
 && echo "$PLONE_MD5 Plone.tgz" | md5sum -c - \
 && tar -xzf Plone.tgz \
 && cp -rv ./Plone-$PLONE_VERSION-UnifiedInstaller/base_skeleton/* /plone/instance/ \
 && cp -v ./Plone-$PLONE_VERSION-UnifiedInstaller/buildout_templates/buildout.cfg /plone/instance/buildout-base.cfg \
 && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT wheel==$WHEEL

COPY buildout.cfg /plone/instance/

ENV PORTAL_PADRAO=1.1.4

RUN  wget -O /plone/instance/portal-padrao-versions.cfg https://raw.githubusercontent.com/plonegovbr/portalpadrao.release/master/$PORTAL_PADRAO/versions.cfg \
 && cd /plone/instance \
 && buildout \
 && rm -rf bin/buildout \
 && apt-get purge -y --auto-remove $buildDeps

FROM base

COPY --from=builder /plone /plone

RUN runDeps="git gosu libjpeg62 libopenjp2-7 libtiff5 libxml2 libxslt1.1 lynx netcat poppler-utils rsync wv" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $runDeps \
    && rm -rf /var/lib/apt/lists/* \
    && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT wheel==$WHEEL \
    && mkdir -p /data/cache \
    && mkdir -p /data/instance \
    && mkdir -p /data/log \
    && ln -s /data/blobstorage /plone/instance/var/blobstorage \
    && ln -s /data/filestorage/ /plone/instance/var/filestorage \
    && find /data  -not -user plone -exec chown plone:plone {} \+ \
    && find /plone -not -user plone -exec chown plone:plone {} \+

VOLUME /data

LABEL maintainer="PloneGov-Br <plonegovbr@plone.org.br>" \
      org.label-schema.name="portalpadrao" \
      org.label-schema.description="Portal Padrão para o Governo Brasileiro" \
      org.label-schema.vendor="PloneGov-Br"

COPY docker-initialize.py docker-entrypoint.sh /

EXPOSE 8080
WORKDIR /plone/instance

HEALTHCHECK --interval=1m --timeout=5s --start-period=1m CMD nc -z -w5 127.0.0.1 8080 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start"]
