#!/bin/bash
#
# Install script for ARK Survival Ascended on Debian 12
#
# Uses Glorious Eggroll's build of Proton
# Please ensure to run this script as root (or at least with sudo)
#
# @LICENSE AGPLv3
# @AUTHOR  Charlie Powell - cdp1337@veraciousnetwork.com
# @SOURCE  https://github.com/cdp1337/ARKSurvivalAscended-Linux
#
# F*** Nitrado


############################################
## Parameter Configuration
############################################

# https://github.com/GloriousEggroll/proton-ge-custom
PROTON_VERSION="9-20"
GAME="ArkSurvivalAscended"
GAMEDIR="/home/steam/$GAME"
# Force installation directory for game
# steam produces varying results, sometimes in ~/.local/share/Steam, other times in ~/Steam
STEAMDIR="/home/steam/.local/share/Steam"
# Specific "filesystem" directory for installed version of Proton
GAMECOMPATDIR="/opt/script-collection/GE-Proton${PROTON_VERSION}/files/share/default_pfx"
# Binary path for Proton
PROTONBIN="/opt/script-collection/GE-Proton${PROTON_VERSION}/proton"
# List of game maps currently available
GAMEMAPS="ark-island ark-aberration ark-club ark-scorched ark-thecenter ark-extinction"
PORT_GAME_START=7701
PORT_GAME_END=7706
PORT_RCON_START=27001
PORT_RCON_END=27006


# scriptlet:install/proton/install.sh
# scriptlet:checks/firewall/get_firewall.sh
# scriptlet:install/steam/install.sh
# scriptlet:install/firewalld/install.sh



############################################
## Pre-exec Checks
############################################

# Only allow running as root
if [ "$LOGNAME" != "root" ]; then
	echo "Please run this script as root! (If you ran with 'su', use 'su -' instead)" >&2
	exit 1
fi

# This script can run on an existing server, but should not run while the game is actively running.
if [ $(ps aux | grep ArkAscendedServer.exe | wc -l) -gt 1 ]; then
	echo "It appears that the ARK server is already running, please stop it before running this script."
	exit 1
fi

# Determine if this is a new installation or an upgrade (/repair)
if [ -e /etc/systemd/system/ark-island.service ]; then
	INSTALLTYPE="upgrade"
else
	INSTALLTYPE="new"
fi

# Determine if there is a firewall already installed, (to prevent issues)
# Addresses Issue #19
FIREWALL=$(get_enabled_firewall)


############################################
## User Prompts (pre setup)
############################################

# Ask the user some information before installing.
echo "================================================================================"
echo "         	  ARK Survival Ascended *unofficial* Installer"
echo ""
if [ "$INSTALLTYPE" == "new" ]; then
	echo "? What is the community name of the server? (e.g. My Awesome ARK Server)"
	echo -n "> "
	read COMMUNITYNAME
	if [ "$COMMUNITYNAME" == "" ]; then
		COMMUNITYNAME="My Awesome ARK Server"
	fi
fi


############################################
## Dependency Installation and Setup
############################################

# Preliminary requirements
apt install -y curl wget sudo

if [ "$FIREWALL" == "none" ]; then
	# No firewall installed, go ahead and install firewalld
	install_firewalld
fi

# Install steam binary and steamcmd
install_steamcmd

# Grab Proton from Glorious Eggroll
install_proton "$PROTON_VERSION"


############################################
## Upgrade Checks
############################################

for MAP in $GAMEMAPS; do
	# Ensure the override directory exists for the admin modifications to the CLI arguments.
	[ -e /etc/systemd/system/${MAP}.service.d ] || mkdir -p /etc/systemd/system/${MAP}.service.d

	# Release 2023.10.31 - Issue #8
	if [ -e /etc/systemd/system/${MAP}.service ]; then
		# Check if the service is already installed and move any modifications to the override.
		# This is important for existing installs so the admin modifications to CLI arguments do not get overwritten.

		if [ ! -e /etc/systemd/system/${MAP}.service.d/override.conf ]; then
			# Override does not exist yet, merge in any changes in the default service file.
			SERVICE_EXEC_LINE="$(grep -E '^ExecStart=' /etc/systemd/system/${MAP}.service)"

			cat > /etc/systemd/system/${MAP}.service.d/override.conf <<EOF
[Service]
$SERVICE_EXEC_LINE
EOF
		fi
	fi
done
## End Release 2023.10.31 - Issue #8


############################################
## Game Installation
############################################

# Install ARK Survival Ascended Dedicated
sudo -u steam /usr/games/steamcmd +force_install_dir $GAMEDIR/AppFiles +login anonymous +app_update 2430930 validate +quit
# STAGING / TESTING - skip ark because it's huge; AppID 90 is Team Fortress 1 (a tiny server useful for testing)
#sudo -u steam /usr/games/steamcmd +force_install_dir $GAMEDIR/AppFiles +login anonymous +app_update 90 validate +quit
if [ $? -ne 0 ]; then
	echo "Could not install ARK Survival Ascended Dedicated Server, exiting"
	exit 1
fi


# Install the systemd service files for ARK Survival Ascended Dedicated Server
for MAP in $GAMEMAPS; do
	# Different maps will have different settings, (to allow them to coexist on the same server)
	if [ "$MAP" == "ark-island" ]; then
		DESC="Island"
		NAME="TheIsland_WP"
		MODS=""
		GAMEPORT=7701
		RCONPORT=27001
	elif [ "$MAP" == "ark-aberration" ]; then
		DESC="Aberration"
		NAME="Aberration_WP"
		MODS=""
		GAMEPORT=7702
		RCONPORT=27002
	elif [ "$MAP" == "ark-club" ]; then
		DESC="Club"
		NAME="BobsMissions_WP"
		MODS="1005639"
		GAMEPORT=7703
		RCONPORT=27003
	elif [ "$MAP" == "ark-scorched" ]; then
		DESC="Scorched"
		NAME="ScorchedEarth_WP"
		MODS=""
		GAMEPORT=7704
		RCONPORT=27004
	elif [ "$MAP" == "ark-thecenter" ]; then
		DESC="TheCenter"
		NAME="TheCenter_WP"
		MODS=""
		GAMEPORT=7705
		RCONPORT=27005
	elif [ "$MAP" == "ark-extinction" ]; then
		DESC="Extinction"
		NAME="Extinction_WP"
		MODS=""
		GAMEPORT=7706
		RCONPORT=27006
	fi


	# Install system service file to be loaded by systemd
	cat > /etc/systemd/system/${MAP}.service <<EOF
[Unit]
Description=ARK Survival Ascended Dedicated Server (${DESC})
After=network.target

[Service]
Type=simple
LimitNOFILE=10000
User=steam
Group=steam
WorkingDirectory=$GAMEDIR/AppFiles/ShooterGame/Binaries/Win64
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
Environment="STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAMDIR"
Environment="STEAM_COMPAT_DATA_PATH=$GAMEDIR/prefixes/$MAP"
# Check $GAMEDIR/services to adjust the CLI arguments
Restart=on-failure
RestartSec=20s

[Install]
WantedBy=multi-user.target
EOF

	if [ ! -e /etc/systemd/system/${MAP}.service.d/override.conf ]; then
		# Override does not exist yet, create boilerplate file.
		# This is the main file that the admin will use to modify CLI arguments,
		# so we do not want to overwrite their work if they have already modified it.
		cat > /etc/systemd/system/${MAP}.service.d/override.conf <<EOF
[Service]
# Edit this line to adjust start parameters of the server
# After modifying, please remember to run `sudo systemctl daemon-reload` to apply changes to the system.
ExecStart=$PROTONBIN run ArkAscendedServer.exe ${NAME}?listen?SessionName="${COMMUNITYNAME} (${DESC})"?RCONPort=${RCONPORT} -port=${GAMEPORT} -servergamelog -mods=$MODS
EOF
    fi

    # Set the owner of the override to steam so that user account can modify it.
    chown steam:steam /etc/systemd/system/${MAP}.service.d/override.conf

    if [ ! -e $GAMEDIR/prefixes/$MAP ]; then
    	# Install a new prefix for this specific map
    	# Proton 9 seems to have issues with launching multiple binaries in the same prefix.
    	[ -d $GAMEDIR/prefixes ] || sudo -u steam mkdir -p $GAMEDIR/prefixes
		sudo -u steam cp $GAMECOMPATDIR $GAMEDIR/prefixes/$MAP -r
	fi
done


# Create start/stop helpers for all maps
cat > $GAMEDIR/start_all.sh <<EOF
#!/bin/bash
#
# Start all ARK server maps that are enabled
GAMEMAPS="$GAMEMAPS"

function start_game {
	echo "Starting game instance \$1..."
	sudo systemctl start \$1
	echo "Waiting 60 seconds for threads to start"
	for i in {0..9}; do
		sleep 6
		echo -n '.'
	done
	# Check status real quick
	sudo systemctl status \$1 | grep Active
}

function update_game {
	echo "Running game update"
	sudo -u steam /usr/games/steamcmd +force_install_dir $GAMEDIR/AppFiles +login anonymous +app_update 2430930 validate +quit
	if [ \$? -ne 0 ]; then
		echo "Game update failed, not starting"
		exit 1
	fi
}

RUNNING=0
for MAP in \$GAMEMAPS; do
	if [ "\$(systemctl is-active $MAP)" == "active" ]; then
		RUNNING=1
	fi
done
if [ \$RUNNING -eq 0 ]; then
	update_game
else
	echo "Game server is already running, not updating"
fi

for MAP in \$GAMEMAPS; do
	if [ "\$(systemctl is-enabled \$MAP)" == "enabled" -a "\$(systemctl is-active \$MAP)" == "inactive" ]; then
		start_game \$MAP
	fi
done
EOF
chown steam:steam $GAMEDIR/start_all.sh
chmod +x $GAMEDIR/start_all.sh


cat > $GAMEDIR/stop_all.sh <<EOF
#!/bin/bash
#
# Stop all ARK server maps that are enabled
GAMEMAPS="$GAMEMAPS"

function stop_game {
	echo "Stopping game instance \$1..."
	sudo systemctl stop \$1
	echo "Waiting 10 seconds for threads to settle"
	for i in {0..9}; do
		echo -n '.'
		sleep 1
	done
	# Check status real quick
	sudo systemctl status \$1 | grep Active
}

for MAP in \$GAMEMAPS; do
	if [ "\$(systemctl is-enabled \$MAP)" == "enabled" -a "\$(systemctl is-active \$MAP)" == "active" ]; then
		stop_game \$MAP
	fi
done
EOF
chown steam:steam $GAMEDIR/stop_all.sh
chmod +x $GAMEDIR/stop_all.sh


# Reload systemd to pick up the new service files
systemctl daemon-reload


############################################
## Security Configuration
############################################

if [ "$FIREWALL" == "ufw" ]; then
	# Enable rules for UFW
	ufw allow ${PORT_GAME_START}:${PORT_GAME_END}/udp
	ufw allow ${PORT_RCON_START}:${PORT_RCON_END}/tcp
elif [ "$FIREWALL" == "firewalld" ]; then
	# Install/enable rules for Firewalld
	[ -d "/etc/firewalld/services" ] || mkdir -p /etc/firewalld/services
    cat > /etc/firewalld/services/ark-survival.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>ARK Survival Ascended</short>
  <description>ARK Survival Ascended game server</description>
  <port port="${PORT_GAME_START}-${PORT_GAME_END}" protocol="udp"/>
  <port port="${PORT_RCON_START}-${PORT_RCON_END}" protocol="tcp"/>
</service>
EOF
    firewall-cmd --permanent --zone=public --add-service=ark-survival
fi


############################################
## Post-Install Configuration
############################################

# Create some helpful links for the user.
[ -e "$GAMEDIR/services" ] || sudo -u steam mkdir -p "$GAMEDIR/services"
for MAP in $GAMEMAPS; do
	[ -h "$GAMEDIR/services/${MAP}.conf" ] || sudo -u steam ln -s /etc/systemd/system/${MAP}.service.d/override.conf "$GAMEDIR/services/${MAP}.conf"
done
[ -h "$GAMEDIR/GameUserSettings.ini" ] || sudo -u steam ln -s $GAMEDIR/AppFiles/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini "$GAMEDIR/GameUserSettings.ini"
[ -h "$GAMEDIR/Game.ini" ] || sudo -u steam ln -s $GAMEDIR/AppFiles/ShooterGame/Saved/Config/WindowsServer/Game.ini "$GAMEDIR/Game.ini"
[ -h "$GAMEDIR/ShooterGame.log" ] || sudo -u steam ln -s $GAMEDIR/AppFiles/ShooterGame/Saved/Logs/ShooterGame.log "$GAMEDIR/ShooterGame.log"


echo "================================================================================"
echo "If everything went well, ARK Survival Ascended should be installed!"
echo ""
for MAP in $GAMEMAPS; do
	echo "? Enable game map ${MAP}? (y/N)"
	echo -n "> "
	read OPT
	if [ "$OPT" == "y" -o "$OPT" == "Y" ]; then
		systemctl enable $MAP
	else
		echo "Not enabling ${MAP}, you can always enable it in the future with 'sudo systemctl enable $MAP'"
	fi
	echo ""
done
echo ""
echo "To restart a map:      sudo systemctl restart NAME-OF-MAP"
echo "To start a map:        sudo systemctl start NAME-OF-MAP"
echo "To stop a map:         sudo systemctl stop NAME-OF-MAP"
echo "Game files:            $GAMEDIR/AppFiles/"
echo "Runtime configuration: $GAMEDIR/services/"
echo "Game log:              $GAMEDIR/ShooterGame.log"
echo "Game user settings:    $GAMEDIR/GameUserSettings.ini"
echo "To start all maps:     $GAMEDIR/start_all.sh"
echo "To stop all maps:      $GAMEDIR/stop_all.sh"
