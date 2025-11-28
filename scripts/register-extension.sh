#!/bin/bash

echo "Registering RAR extension..."

# Kill any running instances
killall RARExt 2>/dev/null || true

# Run the app briefly
open -a /Applications/RARExt.app
sleep 2
killall RARExt 2>/dev/null || true

# Register with pluginkit
pluginkit -a /Applications/RARExt.app/Contents/PlugIns/RAR.appex
pluginkit -e use -i com.example.rarext.RAR

# Restart Finder
killall Finder

echo ""
echo "Extension registered!"
echo "Check System Settings > Extensions > Finder to enable it."
