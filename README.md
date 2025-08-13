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

> **Tip:** If you prefer a version manager, check out `asdf`. It can install and pin Erlang, Elixir, and Node.js per project.

### Installing Elixir

**macOS** (Homebrew):
```bash
brew install elixir
```

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install -y elixir
```

**Windows**:
- Download and install from: https://elixir-lang.org/install.html

Verify installation:
```bash
elixir -v
```
Expected output example:
```
Erlang/OTP 26
Elixir 1.16.x (compiled with Erlang/OTP 26)
```

### Installing Node.js (required by Phoenix for assets)

**macOS (Homebrew)**:
```bash
brew install node
```

**Ubuntu/Debian**:
```bash
sudo apt-get install -y nodejs npm
```

**Windows**:
- Download from https://nodejs.org

Verify installation:
```bash
node -v
npm -v
```

---

### Installing Phoenix

1. Make sure Hex (Elixir’s package manager) is installed/updated:
   ```bash
   mix local.hex --force
   ```

2. Install the Phoenix project generator:
   ```bash
   mix archive.install hex phx_new
   ```

Confirm the generator is available:
```bash
mix phx.new --version
```

---

## Usage

### Stage 1: CLI App
1. Create a new Elixir project:
   ```bash
   mix new task_board
   cd task_board
   ```
2. Define a `Task` struct and functions in `lib/task_board.ex`.
3. Run the program:
   ```bash
   mix run
   ```
4. (Optional) Build as a CLI binary:
   ```bash
   mix escript.build
   ./task_board
   ```

---

### Stage 2: OTP Supervised App
1. Convert task storage into a **GenServer** (e.g., `TaskBoard.TaskServer`).  
2. Add a **Supervisor** in `lib/task_board/application.ex` to start/restart the server.  
3. Start the app with an interactive shell:
   ```bash
   iex -S mix
   ```
4. From IEx, call your API functions to add/list/complete tasks.

---

### Stage 3: Background Jobs
1. Add a `TaskBoard.JobQueue` GenServer to enqueue jobs.
2. Process jobs concurrently (e.g., with `Task.async_stream/3` or worker processes).
3. Add retry logic and status tracking (pending/running/completed/failed).
4. (Optional) Store a recent-activity log in ETS.
5. Run and observe:
   ```bash
   iex -S mix
   ```

---

### Stage 4: Phoenix LiveView Web UI
You can keep your Elixir app as the core **task engine** and create a Phoenix **web** project that calls into it.

1. Create a Phoenix project without Ecto (DB-less to start):
   ```bash
   mix phx.new task_board_web --no-ecto
   cd task_board_web
   ```
2. In `mix.exs`, add your core app (`task_board`) as a dependency (path or umbrella). Example using a local path:
   ```elixir
   defp deps do
     [
       {:phoenix, "~> 1.7.0"},
       {:phoenix_live_view, "~> 0.20.0"},
       {:task_board, path: "../task_board"} # adjust if using umbrella or a different layout
     ]
   end
   ```
   Then fetch deps:
   ```bash
   mix deps.get
   ```
3. Build LiveViews:
   - A **Task List** LiveView that renders tasks from `TaskBoard.TaskServer`.
   - A **Form** to create/update tasks.
   - A **Job Activity** panel that subscribes to updates (Phoenix.PubSub or broadcasts from your GenServers).
4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```
5. Visit:
   ```
   http://localhost:4000
   ```

---

## Supervision Tree Diagram

By Stage 4 your app might look like this:

```
TaskBoard.Application
│
├── TaskBoard.TaskServer (GenServer)
│
├── TaskBoard.JobQueue (GenServer)
│
├── Phoenix.Endpoint (LiveView Web UI)
│
└── Telemetry Supervisor (Phoenix metrics)
```

---

## Next Steps
- **Stage 5**: Add distributed mode with `libcluster` and deploy to Fly.io or Gigalixir.
- **Testing**: Write ExUnit tests for all modules.
- **Docs**: Use `ExDoc` for generated documentation.
