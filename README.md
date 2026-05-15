# PKG Builder

PKG Builder is a small macOS SwiftUI utility for building simple component installer packages from a selected file or folder.

The app is designed around one key idea:

- the source path is where the file or folder currently lives
- the install path is where the package should place it on the destination Mac

The app stages the correct payload structure for you, clears extended attributes, optionally signs with an Installer certificate, and runs `pkgbuild`.

## References

This app was informed by:

- the Scripting OS X article [Building Simple Component Packages](https://scriptingosx.com/2025/08/building-simple-component-packages/)
- the original example script [`build-pkg.sh`](https://github.com/MagerValp/bash-facts/blob/master/build-pkg.sh)

## What It Does

- Accepts a dropped file or folder, or lets you choose one manually
- Separates the source path from the destination install path
- Supports file installs and folder installs
- Lets you save templates for repeated packaging jobs
- Remembers last-used settings
- Shows a live build transcript for troubleshooting
- Optionally signs packages with a detected `Developer ID Installer` certificate

## File Install Modes

When the selected source is a file, PKG Builder offers two install behaviors.

### `Into Folder`

Use this when the install path is a destination folder.

Example:

- source file: `~/Desktop/sticker.jpg`
- install path: `/Users/Shared/Stickers`

Result:

- the package installs `sticker.jpg` inside `/Users/Shared/Stickers/`

This is the safer and more common option when you want to preserve the original filename.

### `Exact File Path`

Use this when the install path should be the final full filename on the destination Mac.

Example:

- source file: `~/Desktop/sticker.jpg`
- install path: `/Users/Shared/Stickers/cover.jpg`

Result:

- the package installs the selected source file as `/Users/Shared/Stickers/cover.jpg`

Use this when you intentionally want the installed filename to be defined by the target path.

## Folder Install Modes

When the selected source is a folder, PKG Builder offers two behaviors.

### `Install Folder`

The selected folder itself is copied into the target path.

### `Install Contents`

Only the contents of the selected folder are copied into the target path.

## Example Workflows

### Install a file into a new folder

- Select `sticker.jpg`
- Choose `Into Folder`
- Enter `/Users/Shared/Stickers`

Installed result:

- `/Users/Shared/Stickers/sticker.jpg`

### Install a script as a specific filename

- Select `cleanup.sh`
- Choose `Exact File Path`
- Enter `/usr/local/bin/cleanup`

Installed result:

- `/usr/local/bin/cleanup`

### Install a folder into `/Library/Scripts`

- Select folder `ScreenSaver`
- Choose `Install Folder`
- Enter `/Library/Scripts`

Installed result:

- `/Library/Scripts/ScreenSaver`

## Build And Run

From the project root:

```bash
./script/build_and_run.sh
```

Build only:

```bash
xcodebuild -project PKGBuilder.xcodeproj -scheme PKGBuilder -configuration Debug -derivedDataPath Build build
```

## Project Layout

- `project.yml`: XcodeGen project spec
- `PKG Builder/`: app source
- `script/build_and_run.sh`: local build/run entrypoint
- `USER-GUIDE.md`: fuller usage guide
