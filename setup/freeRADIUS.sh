
#export rcDir=/etc/freeradius/3.0

# 1. py-script for MAC address Auth  by freeRADIUS x rlm-python3.

${sudo} mkdir -p $rcDir/mods-config/python3
cat << 'EOF' | envsubst | ${sudo} tee $rcDir/mods-config/python3/mac_check.py
import radiusd
import os
import sys

ACK = radiusd.RLM_MODULE_UPDATED, (), (('Auth-Type', 'Accept'),)

def authorize(p):

    radiusd.radlog(radiusd.L_WARN, f'*** python mac_check.authorize(p) called: {p=}')

    # lookup target peer(MAC) info in p(request pairs), from Calling-Station-Id or User-Name.
    target = None
    for pair in p:
        if pair[0] in [ 'User-Name' ]:
            target = pair[1].replace(':', '-').lower()
            break

    radiusd.radlog(radiusd.L_WARN, f'*** python mac_check: {target=}')
    if not target:
        return radiusd.RLM_MODULE_NOOP

    # check policy if target is allowed
    policy = f'$rcDir/data/allowed-devices/{target}'
    radiusd.radlog(radiusd.L_WARN, f'*** python mac_check: check: {policy=}')
    try:
        # policy says allowed
        if os.path.exists(policy):
            return ACK
    except Exception as e:
        radiusd.radlog(radiusd.L_ERR, f'python mac_check.authorize{p=} => Error: {str(e)}')

    radiusd.radlog(radiusd.L_WARN, f'*** python mac_check: returns NOTFOUND')
    return radiusd.RLM_MODULE_NOTFOUND
EOF

# 2. create folder to list allowed-device.
${sudo} mkdir -p  $rcDir/data/allowed-devices
${sudo} chmod 755 $rcDir/data/allowed-devices

# 3. enable mac_check with rlm_python3
cat << 'EOF' | envsubst | ${sudo} tee $rcDir/mods-available/python3_mac
python3 python3_mac {
    mod_path = $rcDir/mods-config/python3
    python_path = $rcDir/mods-config/python3
    module = mac_check
    mod_authorize = ${.module}
    func_authorize = authorize
}
EOF
(cd $rcDir/mods-enabled; ${sudo} ln -sf ../mods-available/python3_mac python3_mac ) 

# 4. add python3_mac for mac_check in sites-enabled/default
${sudo} sed -i '/authorize {/a \
    python3_mac' $rcDir/sites-enabled/default

cat << 'EOF' | ${sudo} tee -a $rcDir/clients.conf
client all {
    ipaddr = 0.0.0.0/0
    proto = *
    secret = testing123
    require_message_authenticator = true
}
EOF

${sudo} chown -R freerad:freerad ${rcDir}

# allowed device example.
# ${sudo} touch $rcDir/data/allowed-devices/00-00-00-00-00-00; ${sudo} chmod 644 $rcDir/data/allowed-devices/00-00-00-00-00-00

