# Containers, Finder, and Link Folders

SimControl makes simulator app data easy to reach from Finder. It exposes app bundle containers, data containers, App Group containers, device data folders, log folders, and an optional symbolic-link folder tree.

## App Bundle Container

The bundle container for an installed app can be opened in Finder. SimControl first tries `simctl get_app_container <device> <bundleID> app` when available, then falls back to the path discovered during app scanning.

If the path cannot be found or cannot be opened, the app shows a clear error instead of silently doing nothing.

## App Data Container

The data container for an installed app can be opened in Finder. SimControl first tries `simctl get_app_container <device> <bundleID> data`, then falls back to the scanner-discovered sandbox path.

The action is available from app details and from the menu bar when the path is known.

## App Group Containers

App Group containers are listed by group identifier. Each group can be opened in Finder, and its path can be copied.

Apple and system groups are hidden by default. They can be shown through Settings when needed.

## Device Data and Log Folders

The device inspector includes actions for opening the simulator data folder and log folder. These folders can also be copied as paths.

If a log folder is missing or unavailable, SimControl keeps the device visible and shows the path state as unavailable.

## Copy Actions

SimControl provides copy actions for common identifiers and paths:

- Device UDID
- Runtime identifier
- Device type identifier
- App bundle identifier
- Bundle container path
- Data container path
- App Group path
- Device data path
- Device log path

## Link Folder

The link folder feature creates a user-visible symbolic-link tree for quick access to simulator app data. It is disabled by default and only runs after the user selects a root folder and enables it.

The generated tree groups links by runtime, device, and app:

```text
<Link Root>/
  <Runtime Name>/
    <Device Name or Device Name_UDID>/
      <App Name or App Name_BundleID>/
        Bundle -> <Bundle Container>
        Sandbox -> <Data Container>
      AppGroups/
        <Group ID> -> <App Group Container>
```

Duplicate device names include the UDID. Duplicate app names include the bundle identifier. Existing user files in the root folder are preserved where possible.

## Rebuild and Cleanup

Users can rebuild the link folder tree from the current simulator snapshot. Stale links can be cleaned after confirmation.

Cleanup only targets links managed by SimControl. It does not delete unrelated files placed in the same root folder.

## Permissions

SimControl distinguishes between "no data" and "permission denied." Permission failures for CoreSimulator folders, link folders, or output folders are shown as actionable errors.

If a sandboxed distribution is supported later, the app will use user-selected folders and security-scoped bookmarks for paths that require explicit access.
