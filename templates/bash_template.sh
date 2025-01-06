#!/bin/bash
#
# Short title for this script
#
# Some description of this script, what it does, and how it works.
#
#
#$ The syntax should be towards the top and lists what arguments are supported.
#$ and what their purpose is.
#$ This field gets rendered in TRMM when running a new script as a tooltip for the user.
#
# Syntax:
#   NONINTERACTIVE=--noninteractive - Run in non-interactive mode, (will not ask for prompts)
#   VERSION=--version=... - Version of Zabbix to install (default: 7.0)
#   SERVER_IP=--server=... - Hostname or IP of Zabbix server
#   CLIENT_HOSTNAME=--hostname=... - Hostname of local device for matching with a Zabbix host entry
#
#$ Arguments that get generated by default for TRMM, each line should be a separate argument
#$ and fully functional within TRMM.
#
# TRMM Arguments:
#   --noninteractive
#   --version=7.0
#   --server={{client.zabbix_hostname}}
#   --hostname={{agent.fqdn}}
#
#$ Environmental variables that get generated by default for TRMM, each line should be a separate key/value
#$ and fully functional within TRMM.
#
# TRMM Environment:
#   BLAH=foo
#   SITE_NAME={{site.name}}
#   CLIENT_NAME={{client.name}}
#   AGENT_NAME={{agent.name}}
#
#$ List of OS support for this script, each line should be short but descriptive
#$ of the OS and version supported.
#$ You can use "Linux-All" for scripts that are pretty OS agnostic.
#
# Supports:
#   Debian 12
#   Ubuntu 24.04
#   Rocky 8, 9
#   CentOS 8, 9
#   RHEL 8, 9
#
# Category:
#
# @LICENSE AGPLv3
# @AUTHOR  Charlie Powell <cdp1337@veraciousnetwork.com>
# @CATEGORY System Monitoring
# @TRMM-TIMEOUT 120
#
# Requirements:
#   List of requirements / dependencies if necessary
#
# TRMM Custom Fields:
#   None | List of custom fields that should be present in TRMM
#   client.some_client_level_field - Some field that should be set at the client level
#   site.some_site_level_field - Some field that should be set at the site level
#   agent.some_agent_level_field - Some field that should be set at the agent level
#
#
# Changelog:
# 	YYYY.MM.DD - Original Release
#   or whatever format you would like to use for indicating changes throughout the life of the script.
#


# compile:usage
# compile:argparse


# Your script here
# Refer to https://docs.tacticalrmm.com/contributing_community_scripts/
# for guidelines when writing TRMM scripts.
#


