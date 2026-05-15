# PKG Builder User Guide

## Overview

PKG Builder creates simple component installer packages from a selected file or folder.

Instead of asking you to manually build a `payload` directory tree first, the app lets you:

- choose the source item
- describe where it should install on the destination Mac
- build the package from that mapping

This avoids a common mistake: confusing the current source location with the final install location.

Example:

- source: `~/Desktop/ScreenSaver`
- install target: `/Library/Scripts`

The app reads from the Desktop path, but it does not assume the package should install back into Desktop.

## Main Concepts

### Source Path

The source path is the file or folder you are packaging.

Examples:

- `~/Desktop/sticker.jpg`
- `~/Desktop/ScreenSaver`

This is only where the item is coming from.

### Install Path

The install path is where the item should land on the destination Mac after the package is run.

Examples:

- `/Users/Shared/Stickers`
- `/Library/Scripts`
- `/usr/local/bin/toolname`

This is the path PKG Builder uses to create the staged payload structure for `pkgbuild`.

## Source Types

PKG Builder supports:

- a single file
- a single folder

You can provide a source by:

- dragging and dropping it onto the app
- clicking `Choose File…`
- clicking `Choose Folder…`

## File Install Modes

When the source is a file, you choose how to interpret the install path.

### `Into Folder`

Meaning:

- the install path is a destination folder
- the selected file keeps its original filename

Example:

- source: `~/Desktop/package-sticker.jpg`
- mode: `Into Folder`
- install path: `/Users/Shared/Stickers`

Result:

- `/Users/Shared/Stickers/package-sticker.jpg`

Use this when:

- you want the original filename preserved
- you are installing a file into a folder that may already exist or may need to be created

This is the best default for most file-based package jobs.

### `Exact File Path`

Meaning:

- the install path is the final installed filename and path

Example:

- source: `~/Desktop/package-sticker.jpg`
- mode: `Exact File Path`
- install path: `/Users/Shared/Stickers/cover.jpg`

Result:

- `/Users/Shared/Stickers/cover.jpg`

Use this when:

- the destination filename must be explicit
- you want the installed name to differ from the source name
- you are packaging an executable or config file that must land at one specific filename

## Folder Install Modes

When the source is a folder, you choose how to interpret the install path.

### `Install Folder`

Meaning:

- the selected folder itself is installed at the destination

Example:

- source folder: `ScreenSaver`
- install path: `/Library/Scripts`

Result:

- `/Library/Scripts/ScreenSaver`

### `Install Contents`

Meaning:

- the contents of the selected folder are installed into the target folder
- the selected folder itself is not recreated as an extra nested folder

Example:

- source folder: `ScreenSaver`
- install path: `/Library/Scripts`

Result:

- contents of `ScreenSaver` are copied directly into `/Library/Scripts`

## Typical Workflows

### Install a JPG into a new shared folder

1. Select the JPG file.
2. Choose `Into Folder`.
3. Set the install path to `/Users/Shared/Stickers`.
4. Enter package name, version, and identifier.
5. Build the package.

Expected installed result:

- the JPG is placed inside `/Users/Shared/Stickers/`

### Install a command-line tool

1. Select the built tool binary.
2. Choose `Exact File Path`.
3. Set the install path to `/usr/local/bin/toolname`.
4. Build the package.

Expected installed result:

- the binary lands at exactly `/usr/local/bin/toolname`

### Install a reusable scripts folder

1. Select the source folder.
2. Choose `Install Folder` if you want the folder name preserved.
3. Set the install path to `/Library/Scripts`.
4. Build the package.

Expected installed result:

- `/Library/Scripts/<SelectedFolderName>`

## Package Metadata

PKG Builder lets you edit:

- package name
- version
- identifier

### Version Bumping

The `Bump Version` button increments the last numeric segment.

Examples:

- `1.0.0` becomes `1.0.1`
- `2.4` becomes `2.5`
- `7` becomes `8`

After a successful build, the app also bumps the version automatically for the next package.

## Output Options

You can save the built `.pkg`:

- beside the source item
- in a chosen working folder
- in a chosen custom folder

The app shows an output preview before building.

## Signing

If the Mac has a valid Installer signing identity, PKG Builder can use it.

The app looks for installer certificates such as:

- `Developer ID Installer`
- `3rd Party Mac Developer Installer`

If no installer certificate is available, the app can still build unsigned packages.

## Templates

Templates help with repeated packaging work.

A template can store:

- package name
- version
- identifier
- install path
- file or folder install behavior
- output location preference
- signing choice

Templates are useful for:

- recurring releases of the same package
- tools that always install to the same path
- package jobs where only the version changes

## Transcript

The transcript panel shows:

- the source being prepared
- the staging location
- the `xattr` command
- the `pkgbuild` command
- success or failure messages

This is the first place to check if a package result is not what you expected.

## Safety Notes

### Source Path Is Not Install Path

Dropping a file or folder does not define where it installs.

Example:

- source: `~/Desktop/MyTool`

This does not mean the package should install into Desktop.

You must choose the install path separately.

### `/Users/...` Install Targets

The app warns when you target a user home folder under `/Users/...`, except for `/Users/Shared`.

That warning exists because packages that install into specific user home folders are often accidental.

## Troubleshooting

### The package installed a file with the wrong name

Check the file install mode:

- use `Into Folder` when the install path is a folder
- use `Exact File Path` when the install path includes the final filename

### The package installed an extra folder level

Check the folder install mode:

- use `Install Folder` to preserve the selected folder
- use `Install Contents` to flatten one level and copy only its contents

### Signing picker is empty

That usually means:

- no valid installer certificate is available in the current keychain
- signing is optional and the package can still be built unsigned

### Build failed

Check the transcript for:

- invalid install path
- missing output folder
- `pkgbuild` errors
- signing errors

## Developer Notes

Project files:

- `project.yml`
- `PKG Builder/Views/ContentView.swift`
- `PKG Builder/Stores/PackageBuilderStore.swift`
- `PKG Builder/Services/PackageBuilderService.swift`

Build command:

```bash
./script/build_and_run.sh
```
