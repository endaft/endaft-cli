# dfat

Operations and utilities for the DFAT (Dart, Flutter, AWS, Terraform) solution templates.

## Installation

```shell
dart pub global activate dfat
```

## Operation

[Check out the examples](example/example.md)

## A First Build

Below is an example of `dfat` output on an initial build when it has to create the docker builder first.

```shell
❯ dfat build

Building package executable...
Built dfat:dfat.
🤖 Processing 'Docker'
   🔎 Checking for image dfat-lambda-api-builder....🔴
   🧱 Building dfat-lambda-api-builder image =>
      🔵 sha256:5344c1c674cb30fadc8dd219c7edeaee2e03a61acc448f99e9a0437899726ffb
   🧱 Building dfat-lambda-api-builder image........✅
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