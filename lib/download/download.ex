defmodule Hatoba.Download do
  use GenServer

  defstruct id: 0,
    status: :not_started,
    url: "",
    pid: nil,
    ref: nil,
    filecount: 0,
    progress: %{},
    metadata: %{},
    output: [],
    dir: nil

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

  ## Output is sha256 of input

  ## GenServer

  def init([id, url]) do
    outdir = Base.encode16(:crypto.hash(:sha256, "#{id}#{url}"))
    {:ok, %__MODULE__{url: url, dir: outdir}}
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:start, _from, %__MODULE__{:status => :not_started} = state) do
    run_task(state)
  end

  def handle_call(:start, _from, %__MODULE__{:status => :running} = state) do
    {:reply, state.pid, state}
  end

  def handle_call(:start, _from, %__MODULE__{:status => :finished} = state) do
    ## TODO: clean up files here
    run_task(%__MODULE__{state | status: :not_started})
  end

  defp run_task(state) do
    {task_type, task_subtype} = state.url
    |> Hatoba.Nani.source_type
    |> Hatoba.Download.Task.from_source_type

    outdir = Path.join("/tmp", state.dir)
    :ok = File.mkdir_p(outdir)

    # make sure this is run outside the task
    parent = self()

    if task_type != nil && task_subtype != nil do
      {:ok, pid} = Task.Supervisor.start_child(Hatoba.TaskSupervisor, fn ->
        task_type.run(task_subtype, parent, outdir, state.url)
      end)
      ref = Process.monitor(pid)
      {:reply, pid, %__MODULE__{state | :status => :started, :pid => pid, :ref => ref}}
    else
      {:reply, nil, %__MODULE__{state | :status => :unknown_type}}
    end
  end


  ## Status from task

  def handle_info({:progress, filename, progress}, state) do
    IO.puts "prog: #{progress}"
    {:noreply, %__MODULE__{state | :progress => Map.put(state.progress, filename, progress)}}
  end

  def handle_info({:metadata, filename, metadata}, state) do
    {:noreply, %__MODULE__{state | :metadata => Map.put(state.metadata, filename, metadata)}}
  end

  def handle_info({:filecount, filecount}, state) do
    {:noreply, %__MODULE__{state | :filecount => filecount}}
  end


  ## Traps

  ## Succeeded with known output files
  def handle_info({:DOWN, ref, :process, pid, {:success, [output]}}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "OK: #{output}"
    {:noreply, %__MODULE__{state | :status => :finished, :output => [output]}}
  end

  ## Succeeded with no output file given
  ## Assume all files in the directory are the output
  def handle_info({:DOWN, ref, :process, pid, :success}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "OK with no given output"
    {:noreply, %__MODULE__{state | :status => :finished}}
  end

  ## Failed with some reason
  def handle_info({:DOWN, ref, :process, pid, {:failed, reason}}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Failed: #{reason}"
    {:noreply, %__MODULE__{state | :status => :failed}}
  end

  ## Exited with :normal
  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Exited!"
    {:noreply, %__MODULE__{state | :status => :finished}}
  end

  ## Exited without some other reason
  def handle_info({:DOWN, ref, :process, pid, status}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Failed with some reason #{status}"
    {:noreply, %__MODULE__{state | :status => :failed}}
  end

  ## Killed
  def handle_info({:EXIT, _from, reason}, state) do
    IO.puts "Failed: #{reason}"
    {:noreply, %__MODULE__{state | :status => :killed}}
  end

  ## Unknown
  def handle_info(info, state) do
    IO.puts "Unknown info: #{info}"
    {:noreply, state}
  end
end
