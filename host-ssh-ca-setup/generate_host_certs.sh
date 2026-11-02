#!/bin/bash

if [ "$( uname )" == "Darwin" ]
then
	date_binary="gdate"
else
	date_binary="date"
fi

#end_date="$( ${date_binary} +%Y)12312359"
end_date="$( ${date_binary} -d "+90 days" +%Y%m%d%H%M%S)"
HOST_CA="${HOST_CA:-~/.ssh/ca/host-CA-ed25519}"
CLIENT_CA="${CLIENT_CA:-~/.ssh/ca/}"
path="${path:-./roles/host-ssh-ca-setup/files/host}"
INVENTORY="${INVENTORY:-../../inventory}"
VAULT_PASSWORD_FILE="${VAULT_PASSWORD_FILE:-./get_pw.sh}"

check_if_certs_exits(){
	test -f ${path}/${1}/ssh_host_ed25519_key || return 1
	test -f ${path}/${1}/ssh_host_ed25519_key.pub || return 1
	test -f ${path}/${1}/ssh_host_ed25519_key-cert.pub || return 1
	return 0
}

vault_encrypt(){
	ansible-vault encrypt ${1} --vault-password-file=${VAULT_PASSWORD_FILE}
}

#vault_decrypt(){
#	ansible-vault encrypt ${1} --vault-password-file=./get_pw.sh
#}

check_if_cert_is_valid(){
	days="${2}"
	valid_to=$(ssh-keygen -L -f "${path}/${1}/ssh_host_ed25519_key-cert.pub" 2>/dev/null | awk -F'to ' '/Valid:|valid from/ {print $2; exit}') 
	expire_epoch=$( ${date_binary} -d "$valid_to" +%s)
	now_epoch=$( ${date_binary} +%s)
	threshold_epoch=$(( $now_epoch + $days * 86400 ))
	
	if [ "$expire_epoch" -le "$now_epoch" ]; then
		echo "$expire_epoch" -le "$now_epoch"
		echo "Certificate already expired on $( ${date_binary} -d "@$expire_epoch")"
		return 1
	elif [ "$expire_epoch" -le "$threshold_epoch" ]; then
		echo "Certificate expires in less than $days days: $( ${date_binary} -d "@$expire_epoch")"
		return 1
	else
		echo "Certificate valid until $( ${date_binary} -d "@$expire_epoch") (more than $days days left)"
		return 0
	fi
 	
}

for HOST in $( awk '$1~/^[A-Za-z0-9._-]*$/ && $1!~/^$/ {print $1}' ${INVENTORY} | sort |uniq )
do
	mkdir -p ${path}/${HOST}
	if check_if_certs_exits ${HOST}
	then
		echo keys for ${HOST} exist
		if check_if_cert_is_valid ${HOST} 30 
		then
			continue
		fi
	else
		echo generating keys for ${HOST}
	fi
 	
	ssh-keygen -N '' -C HOST-KEY -t ed25519 -h -f ${path}/${HOST}/ssh_host_ed25519_key </dev/null
	ssh-keygen -s $HOST_CA -I "${HOST}-host_key-gen_by-ansible_script_$( ${date_binary} +%Y%m%d-%H%M)" -n "${HOST}" -V -1h:$end_date -h ${path}/${HOST}/ssh_host_ed25519_key
 	
	vault_encrypt ${path}/${HOST}/ssh_host_ed25519_key
	#vault_encrypt ${path}/${HOST}/ssh_host_ed25519_key.pub
	#vault_encrypt ${path}/${HOST}/ssh_host_ed25519_key-cert.pub
done
