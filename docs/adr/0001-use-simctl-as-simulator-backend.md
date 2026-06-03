# Use simctl as the Simulator Backend

SimControl will use the active Xcode's `xcrun simctl` commands as its simulator backend for inventory queries and device operations. This keeps the app aligned with the public Xcode toolchain and avoids direct dependence on CoreSimulator private framework behavior or Xcode-internal data stores.

**Considered Options**

- Use `xcrun simctl` for listing, creating, booting, shutting down, erasing, deleting, installing, and launching simulator targets.
- Integrate directly with CoreSimulator private APIs.
- Parse Xcode or CoreSimulator internal data stores directly.

**Consequences**

- The app's behavior and error output should closely follow what `simctl` provides.
- The app must handle command execution, JSON parsing, stdout/stderr capture, and per-command failure states carefully.
- Capabilities not exposed cleanly by `simctl` are outside the initial product scope unless a later decision revisits this backend boundary.
