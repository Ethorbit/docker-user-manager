#!/bin/sh
for f in passwd group shadow gshadow env; do 
    echo '' > "/mnt/$f"
    chown root:root "/mnt/$f"
done

chmod 644 /mnt/passwd /mnt/group /mnt/env
chmod 600 /mnt/shadow /mnt/gshadow

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
    IFS=, read id system password \
        < <(echo "$settings" | yq -r ".groups.$group | [ .id, .system, .password ] | @csv" \
        | sed "s/null\|false//g")

    groupadd "$group" \
        `[[ "$id" =~ [0-9]+ ]] && echo -g "$id"` \
        `[[ ! -z "$system" ]] && echo -r`
        
    if [[ $? -eq 0 ]]; then 
        echo "* $group"
   
        if [[ ! -z "$password" && "$password" != "false" ]]; then
            echo "$group:$password" | chgpasswd
        fi
    fi 
done

echo "Creating users.."

append() {
    var_name="$1"
    val="$2"
    eval "${var_name}=\"\${${var_name}}${val}\""
}

for user in $users; do 
    IFS=, read home primarygroup id password shell system base comment \
        < <(echo "$settings" | \
        yq -r ".users.$user | [ .home, .primarygroup, .id, .password, .shell, .system, .base, .comment ] | @csv" \
        | sed "s/null//g")

    command="useradd $user "
    [[ "$home" = "false" ]] && append "command" "-M " || append "command" "-m "
    [[ ! -z "$home" && "$home" != "false" ]] && append "command" "-d '$home' "
    [[ ! -z "$primarygroup" ]] && append "command" "-g $primarygroup "
    [[ "$id" =~ [0-9]+ ]] && append "command" "-u $id " && [[ -z "$primarygroup" ]] && append "command" "-g $user "
    [[ ! -z "$shell" ]] && append "command" "-s '$shell' " || append "command" "-s /bin/sh "
    [[ ! -z "$system" ]] && append "command" "-r "
    [[ ! -z "$base" ]] && append "command" "-b '$base' "
    [[ ! -z "$comment" ]] && append "command" "-c '$comment' "
    
    while IFS=, read key_value_pair; do
        [[ ! -z "$key_value_pair" ]] && append "command" "-K $key_value_pair "
    done < <(echo "$settings" | yq -r ".users.$user.keys | to_entries | .[] | .value")

    eval "$command"

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
            usermod -a -G "$group" "$user"
            [[ $? -eq 0 ]] && echo "  --> $group"
        done
    fi
done

# Output our user files to the /mnt volume, which 
# other containers can then have mounted as read-only
# to have the same users and groups.
for f in passwd group shadow gshadow; do
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
