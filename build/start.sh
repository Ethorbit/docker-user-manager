#!/bin/sh
for f in passwd group shadow env; do 
    echo '' > "/mnt/$f"
    chown root:root "/mnt/$f"
done

chmod 644 /mnt/passwd /mnt/group /mnt/env
chmod 640 /mnt/shadow

# Create the users and groups specified by settings.yml
if [[ ! -f "/mnt/settings.yml" ]]; then 
    echo "/mnt/settings.yml is missing!"
    exit 1
fi  

settings=$(cat /mnt/settings.yml | envsubst)
groups=$(echo "$settings" | yq ".groups | keys | .[]")
users=$(echo "$settings" | yq ".users | keys | .[]")

echo "Creating groups.."
for group in $groups; do
    IFS=, read id system \
        < <(echo "$settings" | yq -r ".groups.$group | [ .id, .system ] | @csv" \
        | sed "s/null\|false//g")

    addgroup "$group" \
        `[[ "$id" =~ [0-9]+ ]] && echo -g "$id"` \
        `[[ ! -z "$system" ]] && echo -S`

    [[ $? -eq 0 ]] && echo "* $group"
done

echo "Creating users.."
for user in $users; do 
    IFS=, read home id password shell system groups \
        < <(echo "$settings" | \
        yq -r ".users.$user | [ .home, .id, .password, .shell, .system ] | @csv" \
        | sed "s/null//g")
    
    adduser "$user" -D \
        `[[ "$home" = "false" ]] && echo -H` \
        `[[ ! -z "$home" && "$home" != "false" ]] && echo -h "$home"` \
        `[[ "$id" =~ [0-9]+ ]] && echo -G "$user" -u "$id"` \
        `[[ ! -z "$shell" ]] && echo -s "$shell" || echo -s "/bin/sh"` \
        `[[ ! -z "$system" ]] && echo -S`
 
    if [[ $? -eq 0 ]]; then
        echo "* $user"
    
        if [[ ! -z "$password" && "$password" != "false" ]]; then
            echo "$user:$password" | chpasswd
        fi
    fi
done

echo "Adding users to groups.."
for user in $users; do
    groups=`echo "$settings" | yq -r ".users.$user.groups.[]"`
    if [[ ! -z "$groups" ]]; then
        echo "* $user"
        
        for group in $groups; do 
            addgroup "$user" "$group"
            [[ $? -eq 0 ]] && echo "  --> $group"
        done
    fi
done

# Output our user files to the /mnt volume, which 
# other containers can then have mounted as read-only
# to have the same users and groups.
for f in passwd group shadow; do
    cat "/etc/$f" > "/mnt/$f"
done

# Export the uid and gids to an env file which can
# be used in a docker-compose --env-file to make it possible
# to use this container's user and group names instead of
# the ids or the names from the host
getent passwd | while IFS=: read -r user _ uid _; do 
    printf '%s_u=%i\n' "$user" "$uid" >> /mnt/env
done

getent group | while IFS=: read -r group _ gid _; do
    printf '%s_g=%i\n' "$group" "$gid" >> /mnt/env
done

