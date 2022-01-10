## Operation Examples

General operation can be discovered running `dfat`, like:

```shell
❯ dfat

Operations and utilities for the DFAT (Dart, Flutter, AWS, Terraform) solution templates.

Usage: dfat <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:

General
  build       The primary interaction command. This runs an orchestrated build, excluding your app, and produces a .dist
              folder in your workspace root with the outputs for server deployment.
  check       Checks your environment for DFAT required tools.
  install     Installs the required Dockerfile, schema files, and updates the IaC JSON files to use the appropriate
              schemas.

Granular
  aggregate   Performs the DFAT deployment aggregation routine.
  docker      Runs a build in a DFAT docker image, building the image first if needed.
  lambda      Builds and packages lambdas for distribution.
  shared      Builds the shared library for the lambdas and app.

Run "dfat help <command>" for more information about a command.
```

## A Typical Build

A typical build execution should look something like the block below. The docker builder name `dfat-lambda-api-builder` is derived from your `<workspace_dir>-builder` and there are options to override this.

```shell
❯ dfat build

🤖 Processing 'Docker'
   🔎 Checking for image dfat-lambda-api-builder....✅
   🚢 Using docker image dfat-lambda-api-builder....✅
🏁 Finished 'Docker'

🤖 Processing 'Check'
   🔦 Looking for dart..............................✅
   🔦 Looking for git...............................✅
   🔦 Looking for .dfat.............................✅
   🔦 Looking for iac...............................✅
   🔦 Looking for lambdas...........................✅
   🔦 Looking for schemas...........................✅
   🔦 Looking for shared............................✅
🏁 Finished 'Check'

🤖 Processing 'Shared'
   🧼 Cleaning shared...............................✅
   👇 Dependencies for shared.......................✅
   🏃 Runner build shared...........................✅
🏁 Finished 'Shared'

🤖 Processing 'Lambdas'
   🔎 Finding lambdas...............................✅
   ƛ Handling meta =>
     🧼 Cleaning meta...............................✅
     👇 Dependencies for meta.......................✅
     💪 Compiling meta..............................✅
     📦 Packing meta................................✅
   ƛ Handling meta..................................✅
   ƛ Handling todos =>
     🧼 Cleaning todos..............................✅
     👇 Dependencies for todos......................✅
     💪 Compiling todos.............................✅
     📦 Packing todos...............................✅
   ƛ Handling todos.................................✅
🏁 Finished 'Lambdas'

🤖 Processing 'Aggregate'
   📥 Received lambda_meta.zip, lambda_todos.zip
   🚀 Copying lambda_meta.zip.......................✅
   🚀 Copying lambda_todos.zip......................✅
   🔩 Merging IaC definitions.......................✅
   📝 Noting IaC Hash...............................✅
🏁 Finished 'Aggregate'
```