## Operation Examples

General operation can be discovered running `endaft`, like:

```shell
❯ endaft

Operations and utilities for the EnDaft (Dart, Flutter, AWS, Terraform) solution templates.

Usage: endaft <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:

General
  build       The primary interaction command. This runs an orchestrated build, excluding your app, and produces a .dist
              folder in your workspace root with the outputs for server deployment.
  check       Checks your environment for EnDaft required tools.
  install     Installs the required Dockerfile, schema files, and updates the IaC JSON files to use the appropriate
              schemas.
  validate    Validates your solution state and settings for deployment readiness.

Granular
  aggregate   Performs the EnDaft deployment aggregation routine.
  docker      Runs a build in a EnDaft docker image, building the image first if needed.
  lambda      Builds and packages lambdas for distribution.
  shared      Builds the shared library for the lambdas and app.

Run "endaft help <command>" for more information about a command.
```

## A Typical Build

A typical build execution should look something like the block below. The docker builder name `endaft-lambda-api-builder` is derived from your `<workspace_dir>-builder` and there are options to override this.

```shell
❯ endaft build

🐳 Running in endaft-lambda-api-builder...............✅

🤖 Processing Checks
   👀 Looking for dart..............................✅
   👀 Looking for git...............................✅
   📂 Checking for Dockerfile.al2...................✅
   📂 Checking for run.sh...........................✅
🏁 Finished Checks

🤖 Processing Validate
   🧐 shared schema.................................✅
   🧐 lambdas/meta schema...........................✅
   🧐 lambdas/todos schema..........................✅
   🚏 x-check api routes............................✅
🏁 Finished Validate

🤖 Processing Shared
   🧼 Cleaning shared...............................✅
   👇 Dependencies for shared.......................✅
   🏃 Runner build shared...........................✅
🏁 Finished Shared

🤖 Processing Lambdas
   🔎 Finding lambdas...............................✅
   ƛ  Handling meta =>
      🧼 Cleaning meta..............................✅
      👇 Dependencies for meta......................✅
      💪 Compiling meta → bootstrap.................✅
      📦 Packing bootstrap → lambda_meta.zip........✅
   ƛ  Handling meta.................................✅
   ƛ  Handling todos =>
      🧼 Cleaning todos.............................✅
      👇 Dependencies for todos.....................✅
      💪 Compiling todos → bootstrap................✅
      📦 Packing bootstrap → lambda_todos.zip.......✅
   ƛ  Handling todos................................✅
🏁 Finished Lambdas

🤖 Processing Aggregate
   📥 Received lambda_meta.zip, lambda_todos.zip
   🚀 Copying lambda_meta.zip.......................✅
   🚀 Copying lambda_todos.zip......................✅
   🔩 Merging IaC definitions.......................✅
   📝 Noting IaC Hash...............................✅
🏁 Finished Aggregate
```