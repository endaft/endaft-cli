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
โฏ endaft build

๐ค Processing Docker Build
   ๐งฑ Building endaft-lambda-api-builder image =>
      ๐ต sha256:771a4fb143c3861eb36c63f04be09cf5b81e2f1505f47aaad96e94701dd6bc9b
   ๐งฑ Building endaft-lambda-api-builder image........โ
๐ Finished Docker Build
๐ณ Running in endaft-lambda-api-builder...............โ

๐ค Processing Checks
   ๐ Looking for dart..............................โ
   ๐ Looking for git...............................โ
   ๐ Checking for Dockerfile.al2...................โ
   ๐ Checking for run.sh...........................โ
๐ Finished Checks

๐ค Processing Validate
   ๐ง shared schema.................................โ
   ๐ง lambdas/meta schema...........................โ
   ๐ง lambdas/todos schema..........................โ
   ๐ x-check api routes............................โ
๐ Finished Validate

๐ค Processing Shared
   ๐งผ Cleaning shared...............................โ
   ๐ Dependencies for shared.......................โ
   ๐ Runner build shared...........................โ
๐ Finished Shared

๐ค Processing Lambdas
   ๐ Finding lambdas...............................โ
   ฦ  Handling meta =>
      ๐งผ Cleaning meta..............................โ
      ๐ Dependencies for meta......................โ
      ๐ช Compiling meta โ bootstrap.................โ
      ๐ฆ Packing bootstrap โ lambda_meta.zip........โ
   ฦ  Handling meta.................................โ
   ฦ  Handling todos =>
      ๐งผ Cleaning todos.............................โ
      ๐ Dependencies for todos.....................โ
      ๐ช Compiling todos โ bootstrap................โ
      ๐ฆ Packing bootstrap โ lambda_todos.zip.......โ
   ฦ  Handling todos................................โ
๐ Finished Lambdas

๐ค Processing Aggregate
   ๐ฅ Received lambda_meta.zip, lambda_todos.zip
   ๐ Copying lambda_meta.zip.......................โ
   ๐ Copying lambda_todos.zip......................โ
   ๐ฉ Merging IaC definitions.......................โ
   ๐ Noting IaC Hash...............................โ
๐ Finished Aggregate
```