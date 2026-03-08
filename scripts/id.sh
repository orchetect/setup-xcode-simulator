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
# - WORKSPACEPATH           optional
# - SCHEME                  required
# - SIMPLATFORM             required
# - SIMPLATFORM_SHORT       required
# - SIMPLATFORM_REGEX       required
# - SIMDEVICE_REGEX         required
# - OSVERSION_REGEX         optional

# Step outputs produced:
# - destination-platform    Platform string (ie: "iOS Simulator") which can be used verbatim in `xcodebuild destination="platform=X"` in place of X
# - destination-id          ID string (ie: "17FC425F-F336-48DC-8D5A-05DA7BCF7B7D") which can be used verbatim in `xcodebuild destination="id=X"` in place of X

# Note that validation of variables is skipped in this script, as validation already occurred
# in the action step that runs parse-inputs.sh.

echo "Finding matching device simulator..."

# Get full list of all available device simulators installed in the system that are applicable for the given Xcode scheme.
XCODE_OUTPUT=$(xcodebuild -showdestinations -workspace "$WORKSPACEPATH" -scheme "$SCHEME")
XCODE_OUTPUT_REGEX="m/\{\splatform:(.*\sSimulator),.*id:([A-F0-9\-]{36}),.*OS:(\d{1,2}\.\d),.*name:([a-zA-Z0-9\(\)\s]*)\s\}/g"

# Provide diagnostic output of device list matching the specified platform and device.
SIMPATFORM_LIST_PREVIEW=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM_REGEX'/ and $name =~ /'$SIMDEVICE_REGEX'/) { print "- ${name} (${plat} - ${os}) - ${id}"; } }')
if [[ -z $SIMPATFORM_LIST_PREVIEW ]]; then echo "Error: no matching simulators available."; exit 1; fi
echo "Available simulators matching the target:"
echo "$SIMPATFORM_LIST_PREVIEW"

# Parse device list into a format that is easier to parse out.
SIMPLATFORMS=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM_REGEX'/ and $name =~ /'$SIMDEVICE_REGEX'/) { print "${name}\t${plat}\t${os}\t${id}"; } }' | sort -rV)
SIMPLATFORMS_REGEX="m/(.*)\t(.*)\t(.*)\t(.*)/g"

# Find simulator ID
if [[ -n $OSVERSION_REGEX ]]; then
  echo "Finding OS version using regex: ${OSVERSION_REGEX}."
  DESTID=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$OSVERSION_REGEX'/) { print "${id}"; } }' | head -n 1)
  DESTDESC=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$OSVERSION_REGEX'/) { print "${name} (${plat} - ${os}) - ${id}"; } }' | head -n 1)
else
  echo "Finding latest OS version for target."
  LINE=$(echo "${SIMPLATFORMS}" | head -1)
  DESTID=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print $id; }')
  DESTDESC=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
fi

# Exit out if no simulators matched the criteria.
if [[ -z $DESTID ]]; then echo "⛔️ Error: No matching simulators available."; exit 1; fi

# Provide diagnostic output of selected devince simulator info.
echo "🟢 Found device simulator: $DESTDESC"

# Set output variable.
echo "destination-platform=$(echo $SIMPLATFORM)" >> $GITHUB_OUTPUT
echo "destination-id=$(echo $DESTID)" >> $GITHUB_OUTPUT
