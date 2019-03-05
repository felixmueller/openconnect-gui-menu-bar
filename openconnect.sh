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
    echo "| image=iVBORw0KGgoAAAANSUhEUgAAACYAAAAiCAYAAAAzrKu4AAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAABHppVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcE1NOkRlcml2ZWRGcm9tIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgPHN0UmVmOmluc3RhbmNlSUQ+eG1wLmlpZDpGQTdGMTE3NDA3MjA2ODExODNEMUQ5M0NCNjUwQUFDNDwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDpCMzQ0NDBBNDI3MjA2ODExODA4M0QyQTNDOEI4OERCNTwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgPC94bXBNTTpEZXJpdmVkRnJvbT4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+eG1wLmRpZDpEMDk3RDE1RTFCQjkxMUU0QjQwMzgxMjIzMzNFNzhCNDwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOkluc3RhbmNlSUQ+eG1wLmlpZDpEMDk3RDE1RDFCQjkxMUU0QjQwMzgxMjIzMzNFNzhCNDwveG1wTU06SW5zdGFuY2VJRD4KICAgICAgICAgPHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOkIzNDQ0MEE0MjcyMDY4MTE4MDgzRDJBM0M4Qjg4REI1PC94bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+QWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKTwveG1wOkNyZWF0b3JUb29sPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K1WhhigAAAn1JREFUWAnNmLtqVVEQho8GY6NEbb0UFmJjCkF9AiOKaWziS2hKK2GnSvqIb2GhnViLhYg+gSkU74pioZIi/l84A3PGfVmXcyQDP+sy8/8z2WutffbKaLRHbV9mXQcUf0W4LFwQTgtHBOy78Fp4LjwRHgvbwkyN5I3wSdhJxGfFNYIVru507abkPgipBcU4uGhMzeakdF+IiUrHaKFZZQg8ENqK+Kb5e8KycEqYFw4LZwXm8BHTxkWzqrjNFuFfmrsrHBKGjBhi4cQCKbzIVsSKYluaWyxQOycO3KhHjizjBH0UvNAbjU9kqUwGw0XDa5Ij67Q2QYCluCTUGhpo+eKaVFE2cXxPraeSE+I2FOMLIxc5B+26IjyRk7UwyJpRwH6nu+T6dB8JP8Lcfxv6ws6HrA/DuHTIct0Wngk/x6DPXNJSxv11UsRaOy6Bl4LfIr6Pj5he+yOvJyX9NT2K8PuKslyvFHewR2cUC+NnpsZuiWzJ0Wbpjo1B3+cjttPiUp7pjExzsI+ssNUWyh3nJ7bTnspjQrQ3OiPTHP6J8KSiMWf5fkenP5UvgnM5jGc57P3SjS/Yr6pkoaKaqifm83KKvgj2eGnXfUBmP6cw3m+91sjrC+OH92Iv41/nVU29E7xOSh8O3FabxmdPSVFWONxOW5HHAq3d0txiJ2PSYZzSdlItjPj8jcIsK3tu6AMv8nLHoZTJYcplhFPMZYRLMDDLLSTGm05nS3E51zcTiolyx6Yz2HJZjfeAtmQm1ObLmTOdpJZ9tSbE95xPaEJ+rqS/q1P6T5Ulse2fKkfHFc2PW4qpsdyaknPVvMfeJ2cpCLwmDglyl/GtOHD3tv0Flimq4mIzN7UAAAAASUVORK5CYII="
    echo '---'
    echo "VPN trennen | bash='$0' param1=disconnect terminal=false refresh=true image=iVBORw0KGgoAAAANSUhEUgAAACAAAAAiCAYAAAA+stv/AAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAABBNpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIj4KICAgICAgICAgPHhtcE1NOkRlcml2ZWRGcm9tIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgPHN0UmVmOmluc3RhbmNlSUQ+eG1wLmlpZDo3MTg2NDYyQTM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0Nzwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDo3MTg2NDYyQjM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0Nzwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgPC94bXBNTTpEZXJpdmVkRnJvbT4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+eG1wLmRpZDo3MTg2NDYyRDM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0NzwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOkluc3RhbmNlSUQ+eG1wLmlpZDo3MTg2NDYyQzM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0NzwveG1wTU06SW5zdGFuY2VJRD4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgp78tFiAAAEwUlEQVRYCeVX70udZRi+Xn09Ot08NpubNVluOEn7cATD2Lc18oOwJbUWCBOCxqA+9x9EUGEwiFNfXEJLsiLMYgmVRLgtWmcnnRZFxBaooTRt/pie4/Htut/j/e45p8dzzqxv3ezx/vHc931dz4/3Pe+A/7s429mAD4AIC7s3gBqtLwImOfqeBmY0VogumABBX2bDJzhaOEpyNL/DuatsPPAMEM2R50/lJfAh8KYHdHF19+Vrlj3PHZokQA+JvJM9p35OAh8B1wn8iCZvV5PIJyeBTlu9lcDHadCvWVCtRSTiC5tliMS3immNFDDnxlNAfUYxnX8QIHgNC3/mqMpO/rf+OjBNEg+afUySfpyBcfcewbWJamkktvpqh4AHBnmsPtDmn4wd+BQYKQaOmgk223Fd1J46hX0nT2JnczMSs7OYGx7GVF8fVqembCUZsSTQ+yTwvAQDAmT2bBnwvpynMs+o2nTcqipEBgZQ3d7uRxbHxlC2fz9KqquxNjODH0hq4fJlW2kQI8ZyB7BTAgEWt/0lcaiD7dOtC7TjoDka9cGnensxeugQvo1EfP3T2bM+iZbBQVTU12/dI41R8RmfDJrgjgNcfR3pvK5s/ODmZABOv7KtDY3nzuGvS5cw0dmJjfn59ArW1rAUiwGpFO4/cQIbS0u4PTISrM7Wj1tf9y7win8En/NlUwq8qATyHYOQtklJTQ0eu3kTS/E44keO2FIyYktAq+w4dgDHFFx80xa/UEnxMq6RgBsOF9SD4Kd9AgQ86BuFIuXIW+exuJWV/l3KkeZPlQPt7kUeLZ9P/itMZHfkiFRCfAIC8TwUhUJwOEK7d2P91q1gymZw0QdcIjfK6s2mkpx9DA9fu4YdfOal+cbKCjxeOJsUlZfD4dPSNDqKH5uarH31jlGH3DogsWwBzG5e1tDgg0tcQPJJKXdGFpG9EKkzYo572PNujJGxEbT29hIJa3yroJdM5r0H3IF12f0Uwdc5/qt7GHDKt6hK4E/JWeF31bygiyNDbdX5GrHEKlJv9lBb9YGKiokiXpiNvbt2TSiwTppa7O2IuSCzn2Khu3sovbienl4NSqKZrH7wq1UgE8nXWlMrDqeTiEa/SBM4cybGT58ZcXQoCcGTmFPKl/U9iDyu2sumG0pKfmO73wVH5Jeqrq4vF/v7T6fdNKjaopPj43AbG81QTjslr+QtMvg8JZBIvMbjXw121vO8oynHOf8H8JAwVtGXhvqmts3ZYmaN2LW1tXFMTz9HAmMmVqzY894m62Vzy/QozJjatjlbTPNF8xU2S/BXBVzISMwXBm7T+GpvPB7lKlbNouym2b6Zm21Lrg7OLYY97y2GRn1Q/pH8QEjie0QiV2ovXDhPEivaTBLU1gLTz2Vrc+Ys7PG8N+gPEyf4cAzugCaK5n3oojq87Dgv8FN6j5xroaIEtUb8cGnpr1hdfY/mdwTnD/Bd0fy7EVpM6qe6XuF50XB9fYzN7khiIUMbSS4/cufCx49f3AT/Jhtccq07oE24E220j3GE0Nr6eCoWO7gA7ONPuH7maWqg+Yglq4uLp9HRMYmhoauc4IOFKwT3L12QuGnkJCA5JCH/KW3heJSDX28Fyxwz+UPrBBfOVvk3upohLEqApQ4AAAAASUVORK5CYII="
    exit
else
    echo "| image=iVBORw0KGgoAAAANSUhEUgAAACYAAAAiCAYAAAAzrKu4AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAABYlAAAWJQFJUiTwAAAEemlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8eG1wTU06RGVyaXZlZEZyb20gcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICA8c3RSZWY6aW5zdGFuY2VJRD54bXAuaWlkOkZBN0YxMTc0MDcyMDY4MTE4M0QxRDkzQ0I2NTBBQUM0PC9zdFJlZjppbnN0YW5jZUlEPgogICAgICAgICAgICA8c3RSZWY6ZG9jdW1lbnRJRD54bXAuZGlkOkIzNDQ0MEE0MjcyMDY4MTE4MDgzRDJBM0M4Qjg4REI1PC9zdFJlZjpkb2N1bWVudElEPgogICAgICAgICA8L3htcE1NOkRlcml2ZWRGcm9tPgogICAgICAgICA8eG1wTU06RG9jdW1lbnRJRD54bXAuZGlkOkU1OTZENEFCMUJCQjExRTRCNDAzODEyMjMzM0U3OEI0PC94bXBNTTpEb2N1bWVudElEPgogICAgICAgICA8eG1wTU06SW5zdGFuY2VJRD54bXAuaWlkOkU1OTZENEFBMUJCQjExRTRCNDAzODEyMjMzM0U3OEI0PC94bXBNTTpJbnN0YW5jZUlEPgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6QjM0NDQwQTQyNzIwNjgxMTgwODNEMkEzQzhCODhEQjU8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgqCRhlQAAAECklEQVRYCc1YzU8TQRSn1Fq+MSoEI2pE5SBprHKQyFGF6AVOkJjABaI3vXk0/At6VHsBQgKcMBpD4oGDSPSgBAIHIiqBCFL8olEKheLvVzvj2+22u10gcZLHvnmfv87OvHlLTs5/OjxZ4sptb2+vXFpaqvR4PGX5+fklPp9vP2PEYrGNtbW11e3t7XBFRcVCd3f3AsTxLONrc0fAurq69k9NTQWQtAaA8rR3Bga2UdhO1dTUTMJ/I4OppcoWWGtr66n19fVLWJl8ywg2Qqzkmt/vf9Xf3z9rY2pQpwWGX+zp6Oioj0QiZw0eLifFxcXToVBoFKu47SSEJTCCampquoJfetIcBEDXS0pK3i9gNDQ0fMVr+g0bb3Nzc+Hy8nJpJcbq6uppAPGbfbHyH4eGhl44AWcJrKWlpZ77yRR4CwnfDQ8PT0IeM+nMU19jY2MAP+A8FF6p5L4bGBgYlTIr3uBEA+4pgLoojREsggV6OjIy8gFyJyctPjs7u1haWjoHOgYfuXrlgUDgBw7Td5nDzOdKAU8fN7qUAeQvvNInY2Nj36TcCU8f+jKGtGcO5pIyM29YsbKysqDX6z0ujLZQq5739PT8ELKs2ImJiVhtbe2Xzc3NM3BMLARy+MLh8Nb09PRiumByxXLN+wolYhKgltM5O5UzBmNJ+2QumV+qc/apGSs6Krcunjx9dXV140q/02dfX98bxCA5GhoxrxnpkZeXN+emYssYO+E1MJyew6ZAn0xzt1Nu8tugMVAkSeQpS3sANDC88wMw1CMYDK7oiXvmKFxfg+6D6kBFSSJPGXW0SRkaGF6dAX2yoqc4ZCFgvKegYAYf6p6BZJ1LmGtgFs6GUmKhtxPdgoECxe7iDuhQksirjuMc+Jsgw9DAotGoMlQGBYpx+bwh/O6CfwBikSaRvwdSQ9omZBoYysNPZcVnZ2fnQTl3wV8QPj2CV+wjxeDJO9UwNDBs/rDUrKysnJDzPeZTmgINjO2wTI5Xe8LuPpP2O+R9Zn8NjD06Vi2qDNhPzczMqM2rxHv1TL9iyBhnryQzoy0OtLW1lUuZA/4abD6DZPn5ijk7V0mUqcH6Rh/6JoZeMc744cAe/a8q8deL+/MqwBUKmR0bgsEROyMLPX3omxgpHSwbxXg8flkZ8MlGcX5+fthhT+aop5fxTXwCUwowGqVrrdm6VFdXj9tc7nsHDIfA9mMEV9h8VVXVN3F1qZZ774Bx1Qgum8+3wcHBh/TD2BVgulH8G/PfX+wrJniJPbe4kw/efxGz4wyn0sqVX9BogfpR197KOmdlu5syy82fIYH+p0pBQQHrW3FRUVGiZent7X2c9NuVV5kBg2sVCyXBuaFF11kdOF6HDRNkC4x3NX3/7/EHFruVfGee+rUAAAAASUVORK5CYII="
    echo '---'
    echo "VPN verbinden | bash='$0' param1=connect terminal=false refresh=true image=iVBORw0KGgoAAAANSUhEUgAAACAAAAAiCAYAAAA+stv/AAAAAXNSR0IArs4c6QAAAAlwSFlzAAAWJQAAFiUBSVIk8AAABBNpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIj4KICAgICAgICAgPHhtcE1NOkRlcml2ZWRGcm9tIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgPHN0UmVmOmluc3RhbmNlSUQ+eG1wLmlpZDo3MTg2NDYyNjM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0Nzwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDo3MTg2NDYyNzM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0Nzwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgPC94bXBNTTpEZXJpdmVkRnJvbT4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+eG1wLmRpZDo3MTg2NDYyOTM1ODQxMUUyOEMwRkNDMjg0MThFQzQ0NzwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOkluc3RhbmNlSUQ+eG1wLmlpZDo3MTg2NDYyODM1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"
    exit
fi
