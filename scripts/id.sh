#!/usr/bin/env bash
#
# Note that GitHub Actions DO NOT USE THE ZSH SHELL, YOU MUST USE BASH (still as of Mar 2026).
# This script is confirmed to work on both bash and zsh.
#
# References:
# GitHub composite action documentation:
# - https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action
# GitHub Actions exit codes:
# - https://docs.github.com/en/actions/how-tos/create-and-publish-actions/set-exit-codes

# Inputs:
# - SCHEME         required    Xcode scheme name that will be used when enumerating available device simulators.
# - SIMPLATFORM    required    Platform (iOS, tvOS, watchOS, visionOS)
# - SIMDEVICE      optional    Device
# - SIMOS          optional    Platform OS version

# Get full list of all available device simulators installed in the system that are applicable for the given Xcode scheme.
XCODE_OUTPUT=$(xcodebuild -showdestinations -workspace ".swiftpm/xcode/package.xcworkspace" -scheme "$SCHEME")
XCODE_OUTPUT_REGEX="m/\{\splatform:(.*\sSimulator),.*id:([A-F0-9\-]{36}),.*OS:(\d{1,2}\.\d),.*name:([a-zA-Z0-9\(\)\s]*)\s\}/g"

# Provide diagnostic output of device list matching the specified platform and device.
SIMPATFORM_LIST_PREVIEW=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM'/ and $name =~ /'$SIMDEVICE'/) { print "- ${name} (${plat} - ${os}) - ${id}"; } }')
if [[ -z $SIMPATFORM_LIST_PREVIEW ]]; then echo "Error: no matching simulators available."; exit 1; fi
echo "Available $SIMPLATFORM simulators:"
echo "$SIMPATFORM_LIST_PREVIEW"

# Parse device list into a format that is easier to parse out.
SIMPLATFORMS=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM'/ and $name =~ /'$SIMDEVICE'/) { print "${name}\t${plat}\t${os}\t${id}"; } }' | sort -rV)
SIMPLATFORMS_REGEX="m/(.*)\t(.*)\t(.*)\t(.*)/g"

# Find simulator ID
if [[ -z $SIMOS ]]; then
  echo "Finding latest OS version for platform."
  LINE=$(echo "${SIMPLATFORMS}" | head -1)
  DESTID=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print $id; }')
  DESTDESC=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
else
  echo "Finding OS version ${SIMOS}."
  DESTID=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$SIMOS'/) { print "${id}"; } }' | head -n 1)
  DESTDESC=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$SIMOS'/) { print "${name} (${plat} - ${os}) - ${id}"; } }' | head -n 1)
fi

# Exit out if no simulators matched the criteria.
if [[ -z $DESTID ]]; then echo "Error: no matching simulators available."; exit 1; fi

# Provide diagnostic output of selected devince simulator info.
echo "Using device: $DESTDESC"

# Set output variable.
echo "id=$(echo $DESTID)" >> $GITHUB_OUTPUT