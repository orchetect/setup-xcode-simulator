#!/bin/sh

# Inputs used:
# - INPUT_WORKSPACEPATH  optional
# - INPUT_SCHEME         required
# - INPUT_TARGET         required
# - INPUT_OSVERSION      optional

# Step outputs produced:
# - parsed-workspace-path
# - parsed-scheme
# - parsed-platform
# - parsed-platform-regex
# - parsed-device-regex
# - parsed-os-version-regex

# Setup workspace path.
if [[ -z $INPUT_WORKSPACEPATH ]]; then
  # If variable is empty or not set, assume the repo is a Swift Package with the Package.swift file located in the root of the repo.
  WORKSPACEPATH=".swiftpm/xcode/package.xcworkspace"
else
  WORKSPACEPATH="$INPUT_WORKSPACEPATH"
fi

# Provide diagnostic output of workspace path.
echo "Using workspace path: $WORKSPACEPATH"

# Setup Xcode scheme.
SCHEME="$INPUT_SCHEME"

# Provide diagnostic output of Xcode scheme.
echo "Using Xcode scheme: $SCHEME"

# Setup OS version.
OSVERSION_REGEX="$INPUT_OSVERSION"

# Provide diagnostic output of OS version.
echo "Using OS version regex: $OSVERSION_REGEX"

# Interpret platform and device criteria from input target identifier.
# Convert target to lowercase to enable "case-insensitive" matching.
INPUT_TARGET_LOWERCASE=$( tr '[:upper:]' '[:lower:]' <<<"$INPUT_TARGET" )
case $INPUT_TARGET_LOWERCASE in
  ios)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\s"
    ;;

  tvos)
    SIMPLATFORM="tvOS"
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV"
    ;;

  watchos)
    SIMPLATFORM="watchOS"
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSeries"
    ;;

  visionos)
    SIMPLATFORM="visionOS"
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro"
    ;;

  iphone)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\s"
    ;;
  
  iphone-air)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\sAir"
    ;;
  
  iphone-pro)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\sPro\s"
    ;;
  
  iphone-pro-max)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\sPro\sMax"
    ;;
  
  ipad)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\s"
    ;;
  
  ipad-air)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\sAir"
    ;;
  
  ipad-pro)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\sPro"
    ;;
  
  ipad-mini)
    SIMPLATFORM="iOS"
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\smini"
    ;;
  
  tv)
    SIMPLATFORM="tvOS"
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV"
    ;;
  
  tv-4k)
    SIMPLATFORM="tvOS"
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV\s4K"
    ;;
  
  watch)
    SIMPLATFORM="watchOS"
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch"
    ;;
  
  watch-se)
    SIMPLATFORM="watchOS"
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSE"
    ;;
  
  watch-series)
    SIMPLATFORM="watchOS"
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSeries"
    ;;
  
  watch-ultra)
    SIMPLATFORM="watchOS"
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sUltra"
    ;;
    
  visionpro)
    SIMPLATFORM="visionOS"
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro"
    ;;
  
  visionpro-4k)
    SIMPLATFORM="visionOS"
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro\s4K"
    ;;
  
  *)
    # Check for empty string
    if [[ -z $INPUT_TARGET ]]; then echo "Error: No target specified."; exit 1; fi
    
    # Otherwise, use target string as device name regex.
    SIMDEVICE_REGEX="$INPUT_TARGET"
    
    # Determine the platform by querying the simulators
    
    # Get full list of all available device simulators installed in the system that are applicable for the given Xcode scheme.
    XCODE_OUTPUT=$(xcodebuild -showdestinations -workspace "$WORKSPACEPATH" -scheme "$SCHEME")
    XCODE_OUTPUT_REGEX="m/\{\splatform:(.*\sSimulator),.*id:([A-F0-9\-]{36}),.*OS:(\d{1,2}\.\d),.*name:([a-zA-Z0-9\(\)\s]*)\s\}/g"
    
    # Parse out platform name from first sorted result.
    SIMPLATFORM=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($name =~ /'$SIMDEVICE_REGEX'/) { print "${plat}"; } }' | sort -rV | head -n 1)

    if [[ -n $SIMPLATFORM ]]; then
      # Copy to regex as-is
      SIMPLATFORM_REGEX="$SIMPLATFORM"
    else
      # If no platform is found, substitute with a pass-thru regex.
      # This should probably exit with an error code, but being more permissive may be useful.
      SIMPLATFORM="Unknown"
      SIMPLATFORM_REGEX=".*"
    fi
    ;;
esac

# Provide diagnostic output of platform and device regex strings.
echo "Using platform: $SIMPLATFORM"
echo "Using platform name regex: $SIMPLATFORM_REGEX"
echo "Using device name regex: $SIMDEVICE_REGEX"

# Set output variables.
echo "parsed-workspace-path=$(echo $WORKSPACEPATH)" >> $GITHUB_OUTPUT
echo "parsed-scheme=$(echo $SCHEME)" >> $GITHUB_OUTPUT
echo "parsed-platform=$(echo $SIMPLATFORM)" >> $GITHUB_OUTPUT
echo "parsed-platform-regex=$(echo $SIMPLATFORM_REGEX)" >> $GITHUB_OUTPUT
echo "parsed-device-regex=$(echo $SIMDEVICE_REGEX)" >> $GITHUB_OUTPUT
echo "parsed-os-version-regex=$(echo $OSVERSION_REGEX)" >> $GITHUB_OUTPUT
