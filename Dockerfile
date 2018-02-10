FROM debian:stretch

LABEL maintainer="rxnew <rxnew.axdseuan+a@gmail.com>"
LABEL version="1.0"

ENV SLAPD_DOMAIN=example.com \
    SLAPD_ORGANIZATION=example \
    SLAPD_PASSWORD=password \
    SLAPD_CONFIG_PASSWORD=password

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y slapd ldap-utils gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY bin/ /usr/local/bin/
COPY ldif/ /root/ldif/

RUN cd /usr/local/bin && \
    chmod 700 ldap-useradd ldap-userdel ldap-groupadd ldap-groupdel ldap-gpasswd docker-entrypoint.sh

EXPOSE 389

VOLUME ["/var/lib/openldap"]

ENTRYPOINT ["docker-entrypoint.sh"]
