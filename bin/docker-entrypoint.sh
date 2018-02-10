#!/bin/bash

cat <<-EOF | debconf-set-selections
slapd slapd/no_configuration boolean false
slapd slapd/root_password password $SLAPD_CONFIG_PASSWORD
slapd slapd/root_password_again password $SLAPD_CONFIG_PASSWORD
slapd slapd/internal/adminpw password $SLAPD_PASSWORD
slapd slapd/internal/generated_adminpw password $SLAPD_PASSWORD
slapd slapd/password1 password $SLAPD_PASSWORD
slapd slapd/password2 password $SLAPD_PASSWORD
slapd slapd/domain string $SLAPD_DOMAIN
slapd shared/organization string $SLAPD_ORGANIZATION
slapd slapd/backend select HDB
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean false
EOF

dpkg-reconfigure -f noninteractive slapd >/dev/null 2>&1

export SLAPD_BASEDN=$(slapd-basedn)
export SLAPD_DB_CONF=$(basename $(find /etc/ldap/slapd.d/cn\=config -name olcDatabase={*}hdb.ldif) | sed -e s/.[^.]*$//)

sed -i "s/^#BASE.*/BASE ${SLAPD_BASEDN}/g" /etc/ldap/ldap.conf

cd /root/ldif

for file in $(find tmpl -name *.tmpl)
do
    cat $file | envsubst > ${file%.*}
done

mv tmpl/*.ldif .

slapadd -F /etc/ldap/slapd.d -l base.ldif

chown openldap: -R /etc/ldap/slapd.d /var/lib/ldap /var/run/slapd

trap_cmd() {
    service slapd stop
    exit 0
}

trap 'trap_cmd' TERM

service slapd start

for ldif in $(find . -regex '.*[0-9]+.*' | sort)
do
    ldapadd -Y EXTERNAL -H ldapi:/// -f $ldif
done

while :
do
    sleep 1
done
