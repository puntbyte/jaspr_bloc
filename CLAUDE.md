# CLAUDE.md

## Project Overview

State management package for Jaspr — like flutter_bloc or angular_bloc but for Jaspr web
applications. Provides BLoC pattern support so TRT Jaspr apps handle state the same way as TRT
Flutter apps.

## Knowledge Base

All coding rules, workflows, technologies, security docs, and markdown writing rules are
navigable from the knowledge base index:
@../trt-ai-agent-development-system/docs/index.md

## Development Workflow

**MANDATORY:** Follow every step in the workflow below when working on stories in this
repository.
@../trt-ai-agent-development-system/docs/workflows/dart-sdk-workflow.md

## Rules

**MANDATORY:** Switch to the Haiku model before running any git command (status, diff, log, add,
commit, push, pull, branch, etc.). Switch back to your previous model after git work is done.
@../trt-ai-agent-development-system/docs/rules/git-rules.md

**MANDATORY:** Follow every rule in the coding rules below when writing code in this repository.
@../trt-ai-agent-development-system/docs/rules/dart-sdk-coding-rules.md

## Markdown Writing Rules

**MANDATORY:** Follow every rule below when writing or editing any `.md` file in this repository.
@../trt-ai-agent-development-system/docs/rules/markdown-writing-rules.md

## Technology Stack

- **Framework:** Jaspr
- **Language:** Dart

## Commands

- **Get dependencies:** `dart pub get`
- **Format:** `dart format lib/ test/`
- **Analyze:** `dart analyze`
- **Test:** `dart test`

## Stories

@../trt-ai-agent-development-system/projects/jaspr_bloc/stories.md
