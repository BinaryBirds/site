---
slug: run-a-bash-scripts-with-a-swift-plugin
title: Run a bash script with a Swift plugin
description: Run a bash script using a Swift CommandPlugin
date: 2024/06/20
tags: Swift, Swift Plugins

---

## Getting started

For more information about Swift plugins and how to create a Swift plugin, take a look at this helpful [article](https://theswiftdev.com/beginners-guide-to-swift-package-manager-command-plugins/) .

To run a Bash script in a Unix-like operating system, use the `bash` command followed by the script name with the syntax `bash example_script.sh`. This command tells the system to interpret the script using the Bash shell, executing the commands within.

```bash
bash example_script.sh
```

Before the Bash script can be run, we need to make sure it’s executable. This is done using the `chmod` command (short for ‘change mode’). This command changes the permissions of a file:

```bash
chmod +x example_script.sh
```

## Run a script with a CommandPlugin

Let's create a very simple script that cleans up build artifacts and other temporary files from the repository. Save it into a file named `run-clean.sh`.

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
Adding `permissions` can be optional.

To run it with a CommandPlugin, we need to run a `Process` and call `bash run-clean.sh`:


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
After a successful build, the plugin can now be called from the command line with:

```bash
swift package run-clean
```

After starting to run, this question pops up:

```
Plugin ‘RunCleanPlugin’ wants permission to write to the package directory.
Stated reason: “runs run-clean.sh”.
Allow this plugin to write to the package directory? (yes/no)
```

Sadly, it needs to be answered every time before each run, but if we define the plugin without `permissions`, then it is still runnable if we run it like this:

```bash
swift package --disable-sandbox run-clean
```

The `--disable-sandbox` flag disables the sandbox, when executing a subprocess, but this is purely optional.

## Conclusion
The feature itself is here/there, it's mostly useable. 
We created couple useable plugins [here](https://github.com/BinaryBirds/swift-plugins).

However, there is another plugin type: the build tool plugin. The build tool plugin is invoked after package resolution and validation and is given access to an input context that provides information about the target to which the plugin is applied. The plugin has read-only access to the source directory of the target and is only allowed to write to specially designated areas of the build output directory.

This is very limited. For example, we cannot create a plugin that auto-formats all the source code every time before each build. But maybe this will change in the future…