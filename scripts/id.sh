#!/bin/sh

# Note that GitHub Actions DO NOT USE THE ZSH SHELL, YOU MUST USE BASH (still as of Mar 2026).
# This script is confirmed to work on both bash and zsh.
#
# References:
# GitHub composite action documentation:
# - https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action
# GitHub Actions exit codes:
# - https://docs.github.com/en/actions/how-tos/create-and-publish-actions/set-exit-codes

# Inputs:
# - WORKSPACEPATH           required
# - SCHEME                  required
# - SIMPLATFORM             required
# - SIMPLATFORM_SHORT       required
# - SIMPLATFORM_REGEX       required
# - SIMDEVICE_REGEX         required
# - OSVERSION_REGEX         optional

# Step outputs produced:
# - id
# - platform
# - platform-short
# - workspace-path

# Note that validation of variables is skipped in this script, as validation already occurred
# in the action step that runs parse-inputs.sh.

echo "Finding matching device simulator..."

# Get full list of all available device simulators installed in the system that are applicable for the given Xcode scheme.
XCODE_OUTPUT=$(xcodebuild -showdestinations -workspace "$WORKSPACEPATH" -scheme "$SCHEME")
XCODE_OUTPUT_REGEX="m/\{\splatform:(.*\sSimulator),.*id:([A-F0-9\-]{36}),.*OS:(\d{1,2}\.\d),.*name:([a-zA-Z0-9\(\)\s]*)\s\}/g"

# Parse device list into a format that is easier to parse out.
SIMPLATFORMS=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM_REGEX'/ and $name =~ /'$SIMDEVICE_REGEX'/) { print "${name}\t${plat}\t${os}\t${id}"; } }' | sort -rV)
SIMPLATFORMS_REGEX="m/(.*)\t(.*)\t(.*)\t(.*)/g"

# Find simulator ID.
if [[ -n $OSVERSION_REGEX ]]; then
  echo "Finding OS version using regex: ${OSVERSION_REGEX}."
  MATCHES=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$OSVERSION_REGEX'/) { print "${name}\t${plat}\t${os}\t${id}"; } }')
  MATCHESDESC=$(echo "${MATCHES}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
  TOPLINEMATCH=$(echo "${MATCHES}" | head -n 1)
  DESTID=$(echo "${TOPLINEMATCH}" | perl -le 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$OSVERSION_REGEX'/) { print "${id}"; } }')
  DESTDESC=$(echo "${TOPLINEMATCH}" | perl -le 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$OSVERSION_REGEX'/) { print "${name} (${plat} - ${os}) - ${id}"; } }' | head -n 1)
else
  echo "Finding latest OS version for target."
  MATCHESDESC=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
  TOPLINEMATCH=$(echo "${SIMPLATFORMS}" | head -1)
  DESTID=$(echo "${TOPLINEMATCH}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print $id; }')
  DESTDESC=$(echo "${TOPLINEMATCH}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
fi

# Provide diagnostic output of all matching simulators.
echo "Available simulators matching the target:"
echo "$(echo "$MATCHESDESC" | while read line; do echo "- $line"; done)"

# Exit out if no simulators matched the criteria.
if [[ -z $DESTID ]]; then echo "⛔️ Error: No matching simulators available."; exit 1; fi

# Provide diagnostic output of selected devince simulator info.
echo "🟢 Found device simulator: $DESTDESC"

# Set output variable.
echo "id=$(echo $DESTID)" >> $GITHUB_OUTPUT
echo "platform=$(echo $SIMPLATFORM)" >> $GITHUB_OUTPUT
echo "platform-short=$(echo $SIMPLATFORM_SHORT)" >> $GITHUB_OUTPUT
echo "workspace-path=$(echo $WORKSPACEPATH)" >> $GITHUB_OUTPUT