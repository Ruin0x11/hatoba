defmodule Hatoba.Download do
  use GenServer

  defstruct id: 0,
    status: :not_started,
    url: "",
    pid: nil,
    progress: 0,
    ref: nil

  # TODO: can only handle one thing at a time, but registry is supposed to handle multiple
  # so there should only ever be one per ID
  # registry should live one level higher?

  def start_link([id, url]) do
    GenServer.start_link(__MODULE__, [id, url], name: via_tuple(id))
  end

  defp via_tuple(id), do: {:via, Registry, {Registry.Hatoba, id}}

  def start(id) do
    GenServer.call(via_tuple(id), :start)
  end

  def status(id) do
    GenServer.call(via_tuple(id), :status)
  end


  ## GenServer

  def init([id, url]) do
    {:ok, %__MODULE__{ id: id, url: url}}
  end

  def handle_call(:status, _from, %__MODULE__{:status => status, :progress => progress} = state) do
    {:reply, {status, progress}, state}
  end

  def handle_call(:start, _from, %__MODULE__{:status => :not_started} = state) do
    {task_type, task_subtype} = state.url
    |> Hatoba.Nani.source_type
    |> Hatoba.Download.Task.from_source_type

    if task_type != nil && task_subtype != nil do
      {:ok, pid} = Task.Supervisor.start_child(Hatoba.TaskSupervisor, fn ->
        task_type.run(task_subtype, self(), "/tmp", state.url)
      end)
      ref = Process.monitor(pid)
      {:reply, pid, %__MODULE__{:status => :started, :pid => pid, :ref => ref}}
    else
      {:reply, nil, %__MODULE__{:status => :unknown_type}}
    end
  end

  def handle_call(:start, _from, %__MODULE__{:status => :running} = state) do
    {:reply, state.pid, state}
  end

  def handle_call(:start, _from, %__MODULE__{:status => :finished} = state) do
    {:reply, nil, state}
  end


  ## Status from task

  def handle_info({:progress, progress}, state) do
    {:noreply, %__MODULE__{ state | :progress => progress}}
  end

  def handle_info({:success}, state) do
    {:noreply, %__MODULE__{ state | :status => :finished, :progress => 100}}
  end

  def handle_info({:failure, status}, _) do
    IO.inspect "failure with #{status}"
    {:noreply, %__MODULE__{:status => :failure}}
  end


  ## Traps

  def handle_info({:DOWN, _ref, :process, pid, {:failed, reason}}, state) do
    ^pid = state.pid
    IO.puts "Failed: #{reason}"
    {:noreply, %__MODULE__{:status => :failed}}
  end

  def handle_info({:DOWN, _ref, :process, pid, :success}, state) do
    ^pid = state.pid
    IO.puts "OK"
    {:noreply, %__MODULE__{:status => :finished}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _}, %__MODULE__{:status => :finished} = state) do
    ^pid = state.pid
    IO.puts "OK"
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, status}, state) do
    ^pid = state.pid
    IO.puts "Failed with some reason #{status}"
    {:noreply, %__MODULE__{:status => :failed}}
  end

  def handle_info({:EXIT, _from, reason}, _) do
    IO.puts "Failed: #{reason}"
    {:noreply, %__MODULE__{:status => :killed}}
  end
end
