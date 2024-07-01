---
slug: run-a-bash-scripts-with-a-swift-plugin
title: Run a bash script with a Swift plugin
description: Utilize a Swift CommandPlugin to run a Bash script
date: 2024/06/20
tags: Swift, Swift Plugins

---

## Getting started

For comprehensive guidance on Swift plugins and their creation, refer to this [article](https://theswiftdev.com/beginners-guide-to-swift-package-manager-command-plugins/).

To execute a Bash script on a Unix-like operating system, use the `bash` command followed by the script name: `bash example_script.sh`. This command instructs the system to interpret and execute the script using the Bash shell.

```bash
bash example_script.sh
```
Ensure the script is executable by applying the `chmod` command:

```bash
chmod +x example_script.sh
```

## Run a script with a CommandPlugin

Create a simple script to clean up build artifacts and temporary files in the repository. Save this script as `run-clean.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

rm -rf ".build"
rm -rf ".swiftpm"
rm -f "openapi/openapi.yaml"
rm -f "db.sqlite"
rm -f "migration-entries.json"
```

Add a CommandPlugin to the `Package.swift` file: 

```swift
products: [
	.plugin(name: "RunCleanPlugin", targets: ["RunCleanPlugin"]),
]
```

As a target add it as a `.custom`command:

```swift
targets: [
    .plugin(
        name: "RunCleanPlugin",
        capability: .command(
            intent: .custom(
                verb: "run-clean",
                description: "runs run-clean.sh"
            ),
            permissions: [
                .writeToPackageDirectory(reason: "runs run-clean.sh")
            ]
        ),
        dependencies: []
    )
]
```

Note that adding `permissions` is optional.

To run the script with a CommandPlugin, execute a `Process` and call `bash run-clean.sh`:

```swift
import Foundation
import PackagePlugin

@main
struct RunCleanPlugin: CommandPlugin {

	func performCommand(
		context: PackagePlugin.PluginContext, 
    	arguments: [String]
	) async throws {
		let tool = try context.tool(named: "bash")
		let process = Process()
		process.launchPath = tool.path.string
		process.arguments = ["path to 'run-clean.sh'"] + arguments
		try process.run()
		process.waitUntilExit()
    }

}
```

Following a successful build, invoke the plugin from the command line with:

```bash
swift package run-clean
```

Upon execution, you will encounter this prompt:

```
Plugin ‘RunCleanPlugin’ wants permission to write to the package directory.
Stated reason: “runs run-clean.sh”.
Allow this plugin to write to the package directory? (yes/no)
```

This prompt appears with each run. However, if you define the plugin without `permissions`, it remains executable via:

```bash
swift package --disable-sandbox run-clean
```
The `--disable-sandbox` flag disables the sandbox during subprocess execution, though this step is optional.

## Conclusion

This feature is functional and useful. We have developed several practical plugins, available [here](https://github.com/BinaryBirds/swift-plugins).

Additionally, consider the build tool plugin. This plugin type is invoked post-package resolution and validation, providing access to the target’s input context. It has read-only access to the target’s source directory and can write only to designated build output areas.

Despite its limitations, such as the inability to create plugins that auto-format source code pre-build, this may evolve in the future.