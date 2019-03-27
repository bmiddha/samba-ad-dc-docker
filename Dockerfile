FROM ubuntu

LABEL name="Samba Active Directory Domain Controller"
LABEL version="0.1"

# https://wiki.samba.org/index.php/Samba_AD_DC_Port_Usage
EXPOSE 53/tcp 53/udp 88/tcp 88/udp 123/udp 135/tcp 137/udp 138/udp 139/tcp 389/tcp 389/udp 445/tcp 464/tcp 464/udp 636/tcp 3268/tcp 3269/tcp 49152-65535/tcp

# hostname, server_ip, domain, provision_new_domain, realm, admin_password, netbios, admin_user

CMD if [ ! -z $hostname ] && [ ! -z $server_ip ] && [ ! -z $domain ] && [ ! -z $provision_new_domain ] && [ ! -z $realm ] && [ ! -z $admin_password ] &`& [ ! -z $netbios ] && [ ! -z $admin_user ] \
    then \
    echo "Error: Environment variables not set" \
    exit \
    fi \
    \
    apt-get update \
    apt-get upgrade -yq \
    echo "$hostname > /etc/hostname" \
    echo "127.0.0.1     localhost localhost.localdomain" >> /etc/hosts \
    echo "$server_ip     $hostname.$domain     $hostname" >> /etc/hosts \
    apt-get -yq install samba attr winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user \
    systemctl mask smbd nmbd winbind \
    systemctl disable smbd nmbd winbind \
    rm /etc/samba/smb.conf \
    rm /etc/krb5.conf \
    \
    cp /usr/local/samba/private/krb5.conf /etc/krb5.conf \
    \
    if [ $provision_new_domain -eq 1 ] \
    then \
    samba-tool domain provision --use-rfc2307 --realm $realm --domain $domain --server-role dc --dns-backend=SAMBA_INTERNAL --adminpass $admin_password \
    else \
    samba-tool domain join ${domain} DC -U"$netbios\$admin_user" -p $admin_password --dns-backend=SAMBA_INTERNAL \
    fi \
    systemctl enable samba-ad-dc \
    systemctl start samba-ad-dc
