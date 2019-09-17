#!/bin/bash
# Credit for original concept and initial work to: Jesse Jarzynka

# Updated by: Felix Mueller (3-5-19)
#   * removed second profile for split tunneling
#   * renamed vpnc-script parameter and changed to default script path

# Updated by: Felix Mueller (2-24-19)
#   * added server cert and authgroup parameters
#   * added vpnc-script parameter
#   * removed Duo/Yubikey/Google Authenticator
#   * added custom profile for split tunneling
#   * changed icons

# Updated by: Ventz Petkov (8-31-18)
#   * merged feature for token/pin input (ex: Duo/Yubikey/Google Authenticator) contributed by Harry Hoffman <hhoffman@ip-solutions.net>
#   * added option to pick "push/sms/phone" (ex: Duo) vs token/pin (Yubikey/Google Authenticator/Duo)

# Updated by: Ventz Petkov (11-15-17)
#   * cleared up documentation
#   * incremented 'VPN_INTERFACE' to 'utun99' to avoid collisions with other VPNs

# Updated by: Ventz Petkov (9-28-17)
#   * fixed for Mac OS X High Sierra (10.13)

# Updated by: Ventz Petkov (7-24-17)
#   * fixed openconnect (did not work with new 2nd password prompt)
#   * added ability to work with "Duo" 2-factor auth
#   * changed icons

# <bitbar.title>VPN Status</bitbar.title>
# <bitbar.version>v1.1</bitbar.version>
# <bitbar.author>Ventz Petkov</bitbar.author>
# <bitbar.author.github>ventz</bitbar.author.github>
# <bitbar.desc>Connect/Disconnect OpenConnect + show status</bitbar.desc>
# <bitbar.image></bitbar.image>

#########################################################
# USER CHANGES #
#########################################################

# 1.) Updated your sudo config with (sudo visudo -f /etc/sudoers):
# # openconnect
# %admin ALL=(ALL) NOPASSWD: /usr/local/bin/openconnect
# %admin ALL=(ALL) NOPASSWD: /usr/bin/killall -2 openconnect

# 2.) Make sure openconnect binary is located here:
#     (If you don't have it installed: "brew install openconnect")
VPN_EXECUTABLE=/usr/local/bin/openconnect

# 3.) Update your vpnc-script if needed
VPN_VPNC_SCRIPT=/usr/local/etc/vpnc-script

# 4.) Update your AnyConnect VPN host
VPN_HOST="vpn.domain.tld"

# 5.) Update your Server cert
VPN_SERVERCERT="pin-sha256:8fj57980h3fw7h5908v37098537n3908="

# 6.) Update your AnyConnect username
VPN_USERNAME="username"

# 7.) Update your Auth group
VPN_AUTHGROUP="authgroup"

# 8.) Create an encrypted password entry in your OS X Keychain:
#     a.) Open "Keychain Access" and 
#     b.) Click on "login" keychain (top left corner)
#     c.) Click on "Passwords" category (bottom left corner)
#     d.) From the "File" menu, select -> "New Password Item..."
#     e.) For "Keychain Item Name" and "Account Name" use the value for "VPN_HOST" and "VPN_USERNAME" respectively
#     f.) For "Password" enter your VPN AnyConnect password.

# This will retrieve that password securely at run time when you connect, and feed it to openconnect
# No storing passwords unenin plain text files! :)
GET_VPN_PASSWORD="security find-generic-password -wl $VPN_HOST"

#########################################################
# END-OF-USER-SETTINGS #
#########################################################

VPN_INTERFACE="utun99"

# Command to determine if VPN is connected or disconnected
VPN_CONNECTED="/sbin/ifconfig | grep -A3 $VPN_INTERFACE | grep inet"
# Command to run to disconnect VPN
VPN_DISCONNECT_CMD="sudo killall -2 openconnect"

case "$1" in
    connect)
        VPN_PASSWORD=$(eval "$GET_VPN_PASSWORD")
        # VPN connection command, should eventually result in $VPN_CONNECTED,
        # may need to be modified for VPN clients other than openconnect
        echo -e "${VPN_PASSWORD}" | sudo "$VPN_EXECUTABLE" -u "$VPN_USERNAME" --passwd-on-stdin --authgroup "$VPN_AUTHGROUP" -i "$VPN_INTERFACE" "$VPN_HOST" --no-xmlpost --servercert "$VPN_SERVERCERT" --script "$VPN_VPNC_SCRIPT" &> /dev/null &

        # Wait for connection so menu item refreshes instantly
        until eval "$VPN_CONNECTED"; do sleep 3; done
        ;;
    disconnect)
        eval "$VPN_DISCONNECT_CMD"
        # Wait for disconnection so menu item refreshes instantly
        until [ -z "$(eval "$VPN_CONNECTED")" ]; do sleep 1; done
        ;;
esac

if [ -n "$(eval "$VPN_CONNECTED")" ]; then
    echo "| image=iVBORw0KGgoAAAANSUhEUgAAACIAAAAgCAYAAAB3j6rJAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAABYlAAAWJQFJUiTwAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpMwidZAAACaklEQVRYCc2XO04cQRCGzUMYiYccYhHCIQCJA4CIuINDk+wNOAIcghiBRE4AZBDyyJYVIFJkyZbN4/9gq6mdHXZ6ehrJv/RvV3dX/V0z/Zod+hKHEbktiWviovhdnBHBnXgrHov74pH4KGbFuNRa4r34HEl8iSE2C9al0hFjEyj6EYtGMoYUuSkWhdtq2xZXxXlxskts2ujDx8c9qY4WmrVAwI7oxa5V/yGOilXAB19ivAaatZIpvok9CUyLdUEMsT4ZtKPAfPIqLXhL9nBUZLkTsWiYHtqVa4YV3nFBPE2TJBT+CjT8m2GMgbupJQfLnPlNmQ6FlQItv2YYqxQjavXnBIstN9C0B2UsxuzDslrMqS07Znf0iVQ0sGMmRLb8gjgn9oBBObYNuzL+WSVjyYP+6uqdlOmymLg7DAdmZCjHpLEhcgc9dIlNG319uFKLTc18X29aw6zCTp2u6VtJHz49IFtzYA6bgqe1JC5lc3awcyA2bYx3Jn4VA3In8lPKDHQhfgujvBu0nYv44BuQe2pYBwwy6BSlDx98Aw5l0Qi5RZvijwTQYio+wpQ68PltDuwan9WKdXxySRLg71vx9pv7QEt6I6SS+4iPSYTdyVtho/SgpRod8FocNL/qLgXTeiOaTmxJTFgSOT4DUpKwZIkNYEs1+TAy0dQyJIKxKXqhPdVjp8nHpdiMH9Dk4zllcB8TkjCDZHgzfpoIaIvbIocelyMr399NXjTFllw5WDMdsUrUoqv8qvpNp7RkN7G1/adkUdACi+216rF/ejj0PvoTzr0BGPi/QJNz5DbnE7CIEaw1JfJnHa6+AJSxcKGyWRMdAAAAAElFTkSuQmCC"
    echo '---'
    echo "VPN trennen | bash='$0' param1=disconnect terminal=false refresh=true image=iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAA19pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIj4KICAgICAgICAgPGRjOmRlc2NyaXB0aW9uPgogICAgICAgICAgICA8cmRmOkFsdD4KICAgICAgICAgICAgICAgPHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0Ij5tZW51X2Rpc2Nvbm5lY3RlZC5wbmc8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6QWx0PgogICAgICAgICA8L2RjOmRlc2NyaXB0aW9uPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPnRpZmZ1dGlsIHYzMTA8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICAgICAgICAgPHRpZmY6Q29tcHJlc3Npb24+NTwvdGlmZjpDb21wcmVzc2lvbj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6UGhvdG9tZXRyaWNJbnRlcnByZXRhdGlvbj4yPC90aWZmOlBob3RvbWV0cmljSW50ZXJwcmV0YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgodAEJYAAADPUlEQVRIDbVWS0sbURi9Myniq4uUCkJRrG3aigs3NWDa0K66MLQWilZw09KN3RYfyc5dfP0ItyULF/ZBV4UkKphKcGXbKNG4LRbEF5EkPeeaCTOTmcyI9YM7c7/zne87M3fu3HsV4WzK5ORksFgshhRFeQT6XTRvOe0v7ltoK4h9mpmZSaBfKscsb4olCnBqako9Ojp6g0IRuBRxY1ulUina1NS0gPyiVYKl4NjY2G0IfUTrtUpywiCaQns9Pz+fNXOrBMPh8FMMXwzEm2byBf0/eOBXGOa4Ps8gOD4+/gykJRDq9KRL9POo9wKi37QaFcGJiYn7AFNo17Xgf7ofos7D2dnZX6wnBQcHBz0dHR2rTt+sra1NBINB0dXVJZ9lc3NTJBIJsbe3J327C7/pzs5OXywWK3hICoVCbyH23i6BuM/nE6Ojo6K1tVV4PB7Z2Pf7/WJ3d1fs7+/bpqP2La/Xm1teXk6rYMGXU982obm5WYyMjMh4PB4XmH2ysU9jjBwHCyOueDBRnkDwQy0y36K7u1uk02mxuLgojo+PZctkMqKlpUVwqA8ODkQul6tV5kYgEPjON+yvxWKsvb1dUlIpzimjra2tSUDjGKNVXr+KtwtUwSagvr5eImdnZ6aIEBqmcaoIOgBafXxDnw6z7ObzeYlzKM2mYRrHHDf5964B0BZiU+zc7enpEZ2dndIZHh4WJycnBl5DQ4P0ySF3Y2PDEDc5XgrWtIGBAYHFWHI4OeyMHHIdBAWHlFuMrdXVuV/lXHD/UjBjq4ZAoVCoFTbEXHB/U3DVkHWFDpa4VRWXz1eoYS79RZ2bm4sD5THB0lSVg+DOHLhbmFgJVuMZZNqupEMRQ5oDd5rHDvn42Wx2AZk/DNllJ5lMitPTU1eNXBtbL2uc74ckRSKRB5hlXCwdl32bonbwIbaz3mg0+pOEygcigLVuCNj5OmaXfjGcR4whTYypFUE6OHt8BeElujwWXNYOWYs19YUMggyQwCFAd11PvGB/nTXMYqxRJUiQQ9DY2OjHP/oO7jYxl7bNHObqh1GfWzm16UF9nydw7BCPcVZ9jiHi3nkHTdthuA5TZAW/xBJ2jqTdiVur+Q9Hjiqryq3YxgAAAABJRU5ErkJggg=="
    exit
else
    echo "| image=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"
    echo '---'
    echo "VPN verbinden | bash='$0' param1=connect terminal=false refresh=true image=iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAA1xpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIj4KICAgICAgICAgPGRjOmRlc2NyaXB0aW9uPgogICAgICAgICAgICA8cmRmOkFsdD4KICAgICAgICAgICAgICAgPHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0Ij5tZW51X2Nvbm5lY3RlZC5wbmc8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6QWx0PgogICAgICAgICA8L2RjOmRlc2NyaXB0aW9uPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPnRpZmZ1dGlsIHYzMTA8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICAgICAgICAgPHRpZmY6Q29tcHJlc3Npb24+NTwvdGlmZjpDb21wcmVzc2lvbj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6UGhvdG9tZXRyaWNJbnRlcnByZXRhdGlvbj4yPC90aWZmOlBob3RvbWV0cmljSW50ZXJwcmV0YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgrz+1mOAAADaElEQVRIDbVWS08TURQ+d4q8Ii8BNSbG8FBR25IoqCBQHokhGokJATfySNi4YOUKV5K4kI07f0ChxkRJdIEILoRYCA1BFjAkgPIwYUEQBcVGHoVez7k4dTrTmfKQk0x67vd953zTOzP3XgbhggOr67EVAoObmF5jwDM5QBKVMYBlxKYA/AOMszetpXIfgkgbB9aEjuZmkGaKrPXY9gEqMkOrdCia88fp7jEn1vt1LAIhDWs+2NPAz18wDrmhisJhnMEQSOyOyzE6q9XqDOt7rcV+Du14Lyla8e7G/BtOc2VrmexW1wUZ1r23XueMdaAgUi3aR77BQapwlY68U3oEDO/22M9KwIeQiFPI//Tr9QPLeVY6Okn9hGHVyypLdOqEJ9wzS4+3QvnJWshOLhL3MvLdDd1zbTCzMmZ6b/RM1xaz8tqr27ckUsakjNeFM7uQdBUeXnoOV46WQ7QlVlyUE0acWVDv6NTxetLgLNK/FK++YU1CZDI0Wp8IvmuuFZoGK8RFOQVxpDELfIGayMtS47A50PG+mbj4RCVcTCkFz0InOCcfgdf3Q1xjSx44HnsKaKqX1hdgekU2a3PE/uVYr4RzesNMRVxGvF1I3POvdVL3/CuBZSZk6zgtQF4SB56vJbTjGMthAa1vrWopUDBFoxOoAQZ5EgN2Wo2Fytf920Ze308drWCKRidQAxzORCgLsRpX5/QmZiXmCOje+Rb4vbmipiE2Il6MSUPawa/dQbx6QF6stse2jqDhyvK0wA1xhxLVdYb5L98yNPY7DHkkNnBKYdlMEWWJMaODuCj8Ps2CvOil+Wwm2vL7zOggLqyWwSdaaTxBVQc54ODBf8g6D9JD3Rt35LeSq0TsV7hThw7GxHIbmtSgYbRTGW65T6IzCGe8RVMbGEawiEAeLjHTkgcdO8Ttry2ec2Kzj6Eads+5YHXTu6OLtAYx/Nfj35mmvteWhUcL2oC31zGDyj3AXvz2cp0l8gTVBh6QADhUI7axh6ZGJRu4JVUrZiQKGNKgrUzuQsFtTL003md4qZfoqWoUZEg4CWgKMB1W6XabDlMPrRk10RkSSFOQ7pYv46G2AYfThO0wUMsbqFY9jepaXN7MA19labbQVsAldgs/oHwsyFB2GFobMZ8GxgaYn3ek9cn9RiduxeUPTbM7ZQK38NUAAAAASUVORK5CYII="
    exit
fi
