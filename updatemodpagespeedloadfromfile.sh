#!/bin/bash

show_welcome_message() {
    clear
    echo "############################################################"
    echo "#                                                          #"
    echo "#        Auto-generate ModPagespeedLoadFromFile mappings   #"
    echo "#        Made by Dean Williams                             #"
    echo "#        Website: https://webdesires.co.uk                 #"
    echo "#        Version: 0.1                                      #"
    echo "#                                                          #"
    echo "#  Disclaimer: Please ensure you have backups of your      #"
    echo "#  databases before running this script. We hold no        #"
    echo "#  responsibility for any loss of data or damage.          #"
    echo "#                                                          #"
    echo "#  If you find this script useful, please consider         #"
    echo "#  making a donation via PayPal to:                        #"
    echo "#  payments@webdesires.co.uk                               #"
    echo "#                                                          #"
    echo "############################################################"
    echo
    read -p "Do you accept the disclaimer and wish to continue? (y/n): " accept
    if [ "$accept" != "y" ]; then
        echo "Exiting script."
        exit 1
    fi
}

# Only show welcome message if not running from cron
if [ -z "$PS1" ] && [ -z "$SSH_TTY" ] && [ -z "$TERM" ]; then
  # Likely running from cron, skip welcome
  :
else
  show_welcome_message
fi

# Where to write final include
# Detect Apache conf.d directory
if [ -d "/etc/apache2/conf.d" ]; then
  OUTPUT="/etc/apache2/conf.d/pagespeed_loadfromfile.conf"
elif [ -d "/usr/local/apache/conf.d" ]; then
  OUTPUT="/usr/local/apache/conf.d/pagespeed_loadfromfile.conf"
elif [ -d "/etc/httpd/conf.d" ]; then
  OUTPUT="/etc/httpd/conf.d/pagespeed_loadfromfile.conf"
else
  echo "[ERROR] Could not find Apache conf.d directory." >&2
  exit 1
fi
TMP="/tmp/pagespeed_loadfromfile.new"

echo "# Auto-generated ModPagespeedLoadFromFile mappings" > "$TMP"

# Associative array to deduplicate
declare -A MAPPINGS

##########################
# Apex Domain Detection
##########################
is_apex_domain() {
  local domain="$1"

  # UK second-level TLDs
  if [[ "$domain" =~ \.co\.uk$ ]] || [[ "$domain" =~ \.org\.uk$ ]] || [[ "$domain" =~ \.me\.uk$ ]]; then
    nodomain=${domain%.co.uk}
    nodomain=${nodomain%.org.uk}
    nodomain=${nodomain%.me.uk}
    if [[ "$nodomain" != *.* ]]; then
      return 0  # apex
    else
      return 1  # subdomain
    fi
  fi

  # General rule: single dot
  dots=$(echo "$domain" | grep -o '\.' | wc -l)
  if [ "$dots" -eq 1 ]; then
    return 0
  fi

  return 1
}

##########################
# Add domain + www variant
##########################
add_domain() {
  local domain="$1"
  local path="$2"

  # Basic sanity
  [[ "$domain" =~ \. ]] || return

  # Deduplicate
  key="$domain|$path"
  if [[ -z "${MAPPINGS[$key]}" ]]; then
    MAPPINGS[$key]=1
  fi

  # Add www. if apex
  if is_apex_domain "$domain"; then
    wwwdomain="www.$domain"
    wwwkey="$wwwdomain|$path"
    if [[ -z "${MAPPINGS[$wwwkey]}" ]]; then
      MAPPINGS[$wwwkey]=1
    fi
  fi
}

##########################
# Loop all users
##########################
for user in $(ls /var/cpanel/users); do
  USERDATA_DIR="/var/cpanel/userdata/$user"
  [ -d "$USERDATA_DIR" ] || continue

  for yaml in "$USERDATA_DIR"/*; do
    [ -f "$yaml" ] || continue

    # Pull documentroot
    docroot=$(grep '^documentroot:' "$yaml" | awk -F': ' '{print $2}' | xargs)
    [ -d "$docroot" ] || continue

    # ServerName
    servername=$(grep '^servername:' "$yaml" | awk -F': ' '{print $2}' | xargs)
    add_domain "$servername" "$docroot"

    # All aliases
    grep '^  -' "$yaml" | sed 's/^- //' | grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | while read alias; do
      add_domain "$alias" "$docroot"
    done
  done
done

##########################
# Write final
##########################
for key in "${!MAPPINGS[@]}"; do
  domain="${key%%|*}"
  path="${key#*|}"
  echo "ModPagespeedLoadFromFile \"https://$domain\" \"$path\"" >> "$TMP"
done

##########################
# Replace only if changed
##########################
if ! cmp -s "$TMP" "$OUTPUT"; then
  mv "$TMP" "$OUTPUT"
  echo "[INFO] Updated Pagespeed LoadFromFile config. Restarting Apache."
  /scripts/restartsrv_httpd
else
  rm "$TMP"
  echo "[INFO] No changes. Apache not restarted."
fi
