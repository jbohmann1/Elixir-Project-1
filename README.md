# Real-Time Task Board (Elixir + Phoenix LiveView)

A multi-stage learning project that grows from a simple command-line task manager into a fully-fledged, real-time web app using **Elixir** and **Phoenix LiveView**.

---

## Table of Contents
1. [About](#about)
2. [Project Stages](#project-stages)
3. [Installation](#installation)
   - [Installing Elixir](#installing-elixir)
   - [Installing Phoenix](#installing-phoenix)
4. [Usage](#usage)
   - [Stage 1: CLI App](#stage-1-cli-app)
   - [Stage 2: OTP Supervised App](#stage-2-otp-supervised-app)
   - [Stage 3: Background Jobs](#stage-3-background-jobs)
   - [Stage 4: Phoenix LiveView Web UI](#stage-4-phoenix-liveview-web-ui)
5. [Supervision Tree Diagram](#supervision-tree-diagram)
6. [Next Steps](#next-steps)

---

## About

The **Real-Time Task Board** starts simple and gradually introduces Elixir’s unique features:

- **Stage 1**: Command-line task manager
- **Stage 2**: OTP GenServer + Supervisor for resilience
- **Stage 3**: Background job processing with concurrency
- **Stage 4**: Phoenix LiveView for a real-time web interface

---

## Project Stages

| Stage | Description | Key Skills Learned |
|-------|-------------|--------------------|
| 1 | CLI app for adding/listing/completing tasks | Structs, Enum pipelines, file I/O |
| 2 | In-memory GenServer + Supervisor | OTP basics, process state, supervision trees |
| 3 | Background job queue | Concurrency, Task.async_stream, retries |
| 4 | Real-time web interface | Phoenix, LiveView, PubSub |

---

## Installation

### Installing Elixir

**macOS** (using Homebrew):
```bash
brew install elixir
