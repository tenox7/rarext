# RARExt

macOS Finder Quick Actions Extension for creating and extracting RAR archives.

It executes `rar` binary from `/usr/local/bin` to process archives.

![RARExt](rarext.png)


## Installation

- Download and place RAR binary in `/usr/local/bin`
- Install `build/RARExt.pkg`
- Run `/Applications/RARExt.app/Contents/Resources/register-extension.sh`
- Enable extension in `System Settings > General -> Login Items & Extensions > Finder`

## Usage

Select files/folders in Finder → Right-click → Quick Actions → RAR
## Building

```bash
xcodebuild -workspace RARExt.xcworkspace -scheme RARExt -configuration Release -derivedDataPath build clean build
./scripts/create-installer.sh
```

Package created at `build/RARExt.pkg`

## Illegal

Hallucinated entirely by a robot named Claude.

Humans are prohibited from downloading, copying and using this software.
