defmodule Hatoba.Upload do
  use GenServer

  defstruct id: 0,
    parent: nil,
    dl: nil,
    status: :not_started,
    pid: nil,
    ref: nil

  def start_link([parent, id, dl]) do
    GenServer.start_link(__MODULE__, [parent, id, dl], name: via_tuple(id))
  end

  defp via_tuple(id), do: {:via, Registry, {Registry.Hatoba.Upload, id}}

  def start(id) do
    GenServer.call(via_tuple(id), :start)
  end


  ## GenServer

  def init([parent, id, dl]) do
    {:ok, %__MODULE__{id: id, parent: parent, dl: dl}}
  end

  def handle_call(:start, _from, %__MODULE__{:status => :not_started} = state) do
    parent = self()
    {:ok, pid} = Task.Supervisor.start_child(Hatoba.TaskSupervisor, fn ->
      Hatoba.Upload.Task.run(parent, state.dl)
    end)

    ref = Process.monitor(pid)
    {:reply, pid, %__MODULE__{state | :status => :started, :pid => pid, :ref => ref}}
  end


  ## Traps

  ## Succeeded
  def handle_info({:DOWN, ref, :process, pid, :success}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Upload - OK"
    send state.parent, {:upload_success, state.id}
    {:noreply, %__MODULE__{state | :status => :finished}}
  end

  ## Failed with some reason
  def handle_info({:DOWN, ref, :process, pid, {:failed, reason}}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Upload - Failed: #{reason}"
    send state.parent, {:upload_failure, state.id}
    {:noreply, %__MODULE__{state | :status => :failed}}
  end

  ## Exited with :normal
  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Upload - Exited!"
    send state.parent, {:upload_failure, state.id}
    {:noreply, %__MODULE__{state | :status => :failed}}
  end

  ## Exited without some other reason
  def handle_info({:DOWN, ref, :process, pid, status}, state) do
    ^pid = state.pid
    ^ref = state.ref
    IO.puts "Upload - Failed with some reason."
    IO.inspect status
    send state.parent, {:upload_failure, state.id}
    {:noreply, %__MODULE__{state | :status => :failed}}
  end

  ## Killed
  def handle_info({:EXIT, _from, reason}, state) do
    IO.puts "Upload - Failed: #{reason}"
    send state.parent, {:upload_failure, state.id}
    {:noreply, %__MODULE__{state | :status => :killed}}
  end

  ## Unknown
  def handle_info(info, state) do
    IO.puts "Upload - Unknown info: #{info}"
    {:noreply, state}
  end
end

defmodule Hatoba.UploadType do
  defstruct type: :move,
    arg: "/tmp/hatoba_finished"
end
