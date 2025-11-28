# RARExt

macOS Finder Action Extension for creating and extracting RAR archives.

## Requirements

- macOS 15.0+
- RAR binary at `/usr/local/bin/rar`

## Installation

1. Install `build/RARExt.pkg`
2. Run `/Applications/RARExt.app/Contents/Resources/register-extension.sh`
3. Enable extension in System Settings > Extensions > Finder

## Usage

Select files/folders in Finder → Right-click → Quick Actions → RAR

- **Single .rar file**: Extract archive
- **Other files/folders**: Create archive

## Building

```bash
xcodebuild -workspace RARExt.xcworkspace -scheme RARExt -configuration Release -derivedDataPath build clean build
./scripts/create-installer.sh
```

Package created at `build/RARExt.pkg`
