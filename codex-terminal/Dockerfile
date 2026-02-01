ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache     bash     curl     nano     nodejs     npm     python3     py3-pip     py3-requests     py3-aiohttp     py3-yaml     py3-beautifulsoup4     git     vim     wget     jq     tree     yq

WORKDIR /config

COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh     && chmod +x /opt/scripts/*.sh

CMD ["/run.sh"]
