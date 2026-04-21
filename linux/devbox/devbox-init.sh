#!/usr/bin/env bash
set -eu

# Expected env vars:
# DEVBOX_USER
# DEVBOX_GROUP
# DEVBOX_UID
# DEVBOX_GID
# DEVBOX_CREATE_USER
# DEVBOX_WORKDIR

DEVBOX_USER="${DEVBOX_USER:-dev}"
DEVBOX_GROUP="${DEVBOX_GROUP:-dev}"
DEVBOX_UID="${DEVBOX_UID:-1000}"
DEVBOX_GID="${DEVBOX_GID:-1000}"
DEVBOX_CREATE_USER="${DEVBOX_CREATE_USER:-yes}"
DEVBOX_WORKDIR="${DEVBOX_WORKDIR:-/workspace}"

mkdir -p /var/run/sshd /etc/devbox "${DEVBOX_WORKDIR}"
ssh-keygen -A >/dev/null 2>&1 || true

if [ "${DEVBOX_CREATE_USER}" = "yes" ] && [ "${DEVBOX_USER}" != "root" ]; then
    REQUESTED_USER="${DEVBOX_USER}"
    REQUESTED_GROUP="${DEVBOX_GROUP}"

    # Ensure group exists for target GID
    if getent group "${DEVBOX_GID}" >/dev/null 2>&1; then
        EXISTING_GROUP="$(getent group "${DEVBOX_GID}" | cut -d: -f1)"
        if [ "${EXISTING_GROUP}" != "${REQUESTED_GROUP}" ]; then
            if getent group "${REQUESTED_GROUP}" >/dev/null 2>&1; then
                groupdel "${REQUESTED_GROUP}" >/dev/null 2>&1 || true
            fi
            groupmod -n "${REQUESTED_GROUP}" "${EXISTING_GROUP}" >/dev/null 2>&1 || true
            DEVBOX_GROUP="${REQUESTED_GROUP}"
        else
            DEVBOX_GROUP="${EXISTING_GROUP}"
        fi
    else
        if getent group "${DEVBOX_GROUP}" >/dev/null 2>&1; then
            groupmod -g "${DEVBOX_GID}" "${DEVBOX_GROUP}" || true
        else
            groupadd -g "${DEVBOX_GID}" "${DEVBOX_GROUP}"
        fi
    fi

    # Ensure user exists for target UID/GID
    if getent passwd "${DEVBOX_UID}" >/dev/null 2>&1; then
        EXISTING_USER="$(getent passwd "${DEVBOX_UID}" | cut -d: -f1)"
        if [ "${EXISTING_USER}" != "${REQUESTED_USER}" ]; then
            if id -u "${REQUESTED_USER}" >/dev/null 2>&1; then
                userdel -r "${REQUESTED_USER}" >/dev/null 2>&1 || true
            fi
            usermod -l "${REQUESTED_USER}" -d "/home/${REQUESTED_USER}" -m "${EXISTING_USER}" >/dev/null 2>&1 || true
            DEVBOX_USER="${REQUESTED_USER}"
        else
            DEVBOX_USER="${EXISTING_USER}"
        fi
        usermod -g "${DEVBOX_GROUP}" -s /bin/bash "${DEVBOX_USER}" >/dev/null 2>&1 || true
    else
        if id -u "${DEVBOX_USER}" >/dev/null 2>&1; then
            usermod -u "${DEVBOX_UID}" -g "${DEVBOX_GID}" -s /bin/bash "${DEVBOX_USER}" || true
        else
            useradd -m -s /bin/bash -u "${DEVBOX_UID}" -g "${DEVBOX_GID}" "${DEVBOX_USER}"
        fi
    fi

    USER_HOME="$(getent passwd "${DEVBOX_USER}" | cut -d: -f6)"
    mkdir -p "${USER_HOME}/.ssh"
    chmod 700 "${USER_HOME}/.ssh"
    touch "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    chown -R "${DEVBOX_UID}:${DEVBOX_GID}" "${USER_HOME}/.ssh"

    # Optional passwordless sudo for the dev user
    mkdir -p /etc/sudoers.d
    echo "${DEVBOX_USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-devbox-user
    chmod 440 /etc/sudoers.d/90-devbox-user

    # Keep workspace ownership sane when possible
    chown "${DEVBOX_UID}:${DEVBOX_GID}" "${DEVBOX_WORKDIR}" 2>/dev/null || true
else
    DEVBOX_CREATE_USER="no"
    DEVBOX_USER="root"
    DEVBOX_GROUP="root"
    DEVBOX_UID="$(id -u root)"
    DEVBOX_GID="$(id -g root)"
    USER_HOME="/root"
    mkdir -p "${USER_HOME}/.ssh"
    chmod 700 "${USER_HOME}/.ssh"
    touch "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    chown -R root:root "${USER_HOME}/.ssh"
    rm -f /etc/sudoers.d/90-devbox-user 2>/dev/null || true
fi

# Persist resolved user info
cat >/etc/devbox/user.env <<EOF
DEVBOX_CREATE_USER=${DEVBOX_CREATE_USER}
DEVBOX_USER=${DEVBOX_USER}
DEVBOX_GROUP=${DEVBOX_GROUP}
DEVBOX_UID=${DEVBOX_UID}
DEVBOX_GID=${DEVBOX_GID}
DEVBOX_HOME=${USER_HOME}
DEVBOX_WORKDIR=${DEVBOX_WORKDIR}
EOF

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
