#!/bin/sh
set -e

echo "Activating feature 'passthrough'"
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"
echo ""
echo "- Make sure to pass though your GPU"
echo "- If running docker with a user namespace: Make sure to use userns_mode: host"

# Check if the create_user option is set to true
if [ "$CREATE_USER" = true ] && [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != "root" ]; then
	# Create the passthrough user (allow non unique ids if they already exist)
	echo "Creating passthrough user: $_REMOTE_USER"
	groupadd -g 1000 -o "$_REMOTE_USER"
	useradd -u 1000 -g 1000 -o -m -d "$_REMOTE_USER_HOME" "$_REMOTE_USER"
fi

# Back up remote user home directory
if [ -n "$_REMOTE_USER_HOME" ]; then
	mkdir -p /etc/backup/home
	cp -ar "$_REMOTE_USER_HOME" -t "/etc/backup/home"
fi

# Write restore
REMOTE_USER_HOME_BASENAME=$(basename "$_REMOTE_USER_HOME")
REMOTE_USER_HOME_DIRNAME=$(dirname "$_REMOTE_USER_HOME")
mkdir -p /etc/entrypoint/passthrough
cat >/etc/entrypoint/passthrough/entrypoint.sh \
	<<EOF
#!/bin/sh
mkdir -p ${REMOTE_USER_HOME_DIRNAME}
cp -ar "/etc/backup/home/${REMOTE_USER_HOME_BASENAME}" -t ${REMOTE_USER_HOME_DIRNAME}
EOF

chmod +x /etc/entrypoint/passthrough/entrypoint.sh

# "securityOpt": {
#     "syscalls": [
#       {
#         "names": ["clone", "unshare", "arch_prctl", "chroot", "ptrace"]
#       }
#     ]
#   }
