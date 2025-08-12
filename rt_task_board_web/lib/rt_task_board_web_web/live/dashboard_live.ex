defmodule RtTaskBoardWebWeb.DashboardLive do
  use RtTaskBoardWebWeb, :live_view
  # (do NOT import CoreComponents for now)

  alias RTTaskBoard.{Store, JobQueue, Task}
  alias RTTaskBoard.Events

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(RtTaskBoardWeb.PubSub, Events.topic())

    {:ok,
     socket
     |> assign(:tasks, Store.list())
     |> assign(:jobs, JobQueue.jobs())}
  end

  # PubSub messages
  @impl true
  def handle_info({:rt_event, :task_added, %Task{} = task}, socket) do
    {:noreply, assign(socket, :tasks, upsert_by_id(socket.assigns.tasks, task))}
  end

  def handle_info({:rt_event, :task_updated, %Task{} = task}, socket) do
    {:noreply, assign(socket, :tasks, upsert_by_id(socket.assigns.tasks, task))}
  end

  def handle_info({:rt_event, :job_updated, job}, socket) do
    {:noreply, assign(socket, :jobs, upsert_by_id(socket.assigns.jobs, job))}
  end

  # UI events
  @impl true
  def handle_event("add_task", %{"task" => %{"title" => title, "description" => desc}}, socket) do
    _ = Store.add(title, desc)
    {:noreply, socket}
  end

  def handle_event("mark_done", %{"id" => id}, socket) do
    with {int, ""} <- Integer.parse(id), do: :ok = Store.done(int)
    {:noreply, socket}
  end

  def handle_event("enqueue_subtasks", %{"id" => id}, socket) do
    with {int, ""} <- Integer.parse(id),
         %Task{} = t <- Enum.find(socket.assigns.tasks, &(&1.id == int)) do
      JobQueue.enqueue_subtasks(t)
    end
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6 space-y-8">
      <h1 class="text-3xl font-semibold">Task Board</h1>

      <!-- Add Task (plain HTML form) -->
      <section class="p-4 rounded-lg border">
        <h2 class="text-xl font-medium mb-3">Add Task</h2>
        <form phx-submit="add_task" id="new-task-form" class="space-y-2">
          <input type="text" name="task[title]" placeholder="Title" class="border px-2 py-1 rounded w-full" />
          <input type="text" name="task[description]" placeholder="Description (optional)" class="border px-2 py-1 rounded w-full" />
          <button type="submit" class="px-3 py-1 border rounded">Add</button>
        </form>
      </section>

      <!-- Tasks -->
      <section class="p-4 rounded-lg border">
        <h2 class="text-xl font-medium mb-3">Tasks</h2>
        <%= if @tasks == [] do %>
          <p class="text-slate-500">No tasks yet.</p>
        <% else %>
          <ul class="space-y-2">
            <%= for t <- Enum.sort_by(@tasks, & &1.id) do %>
              <li class="flex items-center gap-4">
                <span class={"inline-block w-6 text-right #{if t.status == "done", do: "text-green-600"}"}><%= t.id %></span>
                <span class={"flex-1 #{if t.status == "done", do: "line-through text-slate-500"}"}>
                  <%= t.title %>
                  <%= if t.description not in [nil, ""] do %>
                    <span class="text-slate-500">— <%= t.description %></span>
                  <% end %>
                </span>
                <%= unless t.status == "done" do %>
                  <button phx-click="mark_done" phx-value-id={t.id} class="px-2 py-1 border rounded">Done</button>
                <% end %>
                <button phx-click="enqueue_subtasks" phx-value-id={t.id} class="px-2 py-1 border rounded">Subtasks</button>
              </li>
            <% end %>
          </ul>
        <% end %>
      </section>

      <!-- Jobs -->
      <section class="p-4 rounded-lg border">
        <h2 class="text-xl font-medium mb-3">Jobs</h2>
        <div class="grid md:grid-cols-4 gap-4">
          <%= for status <- [:pending, :running, :completed, :failed] do %>
            <div class="border rounded p-3">
              <h3 class="font-medium capitalize mb-2"><%= status %></h3>
              <ul class="space-y-1">
                <%= for j <- Enum.filter(@jobs, &(&1.status == status)) |> Enum.sort_by(& &1.id) do %>
                  <li class="text-sm">
                    #<%= j.id %> task=<%= j.task_id %> type=<%= inspect(j.type) %> (<%= j.attempts %>/<%= j.max_attempts %>)
                    <%= if j.last_error do %>
                      <div class="text-red-600 truncate"><%= j.last_error %></div>
                    <% end %>
                  </li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      </section>
    </div>
    """
  end

  defp upsert_by_id(list, item) do
    case Enum.find_index(list, &(&1.id == item.id)) do
      nil -> [item | list]
      idx -> List.replace_at(list, idx, item)
    end
  end
end
