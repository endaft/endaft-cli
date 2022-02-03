[![build](https://github.com/endaft/endaft-cli/actions/workflows/workflow_build.yml/badge.svg)](https://github.com/endaft/endaft-cli/actions/workflows/workflow_build.yml)

# EnDaft

Operations and utilities for the EnDaft solution templates.

## Installation

```shell
dart pub global activate endaft
```

## Operation

[Check out the examples](https://github.com/endaft/endaft-cli/example/example.md)

## A First Build

Below is an example of `endaft` output on an initial build when it has to create the docker builder first.

```shell
❯ endaft build

🤖 Processing Docker Build
   🧱 Building endaft-lambda-api-builder image =>
      🔵 sha256:771a4fb143c3861eb36c63f04be09cf5b81e2f1505f47aaad96e94701dd6bc9b
   🧱 Building endaft-lambda-api-builder image........✅
🏁 Finished Docker Build
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