defmodule Hatoba.Queue do
  use GenServer

  defstruct downloading: %MapSet{},
    finished: %MapSet{},
    uploading: %MapSet{},
    failed: %MapSet{},
    uploads_failed: %MapSet{},
    queued: :queue.from_list([]),
    next_id: 0,
    next_upload_id: 0

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: :download_queue)
  end

  def status do
    GenServer.call(:download_queue, {:status})
  end

  def add(arg) when is_list(arg) do
    Enum.each(arg, fn(a) ->
      GenServer.call(:download_queue, {:add, a})
    end)
  end

  def add(arg) do
    GenServer.call(:download_queue, {:add, arg})
  end

  def clear do
    GenServer.call(:download_queue, {:clear})
  end

  ## GenServer

  def init(:ok), do: {:ok, %__MODULE__{}}

  def handle_call({:status}, _from, state) do
    [down, up, fin, fail] =
      [state.downloading, state.uploading, state.finished, state.failed]
    |> Enum.map(fn(x) -> Enum.map(x, &(Hatoba.Download.status(&1) |> Map.from_struct)) end)
    {:reply, %{downloading: down, uploading: up, finished: fin, failed: fail}, state}
  end

  def handle_call({:clear}, _from, state) do
    {:reply, :ok, %__MODULE__{next_id: state.next_id}}
  end

  def handle_call({:add, arg}, _from, %__MODULE__{} = state) do
    do_add(arg, state)
  end

  def handle_call({:add, arg, dest}, _from, %__MODULE__{} = state) do
    do_add(arg, state, dest)
  end

  defp do_add(arg, state, dest \\ %Hatoba.UploadType{}) do
    %__MODULE__{downloading: downloading, queued: queued, next_id: next_id} = state

    IO.inspect "queue #{arg}"

    {new_dl, new_q} = if Kernel.map_size(downloading) >= 10 do
      {downloading, :queue.in({next_id, {arg, dest}}, queued)}
    else
      {run_job(downloading, next_id, arg, dest), queued}
    end

    {:reply, next_id, %__MODULE__{ state |
                              downloading: new_dl,
                              queued: new_q,
                              next_id: next_id + 1 }}
  end

  def handle_info({:download_success, id}, state) do
    IO.inspect "done #{id}"
    {new_dl, new_q} =
      pop_next(state.queued, state.downloading, id)

    dl = Hatoba.Download.status(id)
    {:noreply, %__MODULE__{ state |
                            :downloading =>  new_dl,
                            :queued => new_q,
                            :uploading => start_upload(state.uploading, state.next_upload_id, dl),
                            :next_upload_id => state.next_upload_id + 1
                          }}
  end

  def handle_info({:download_failure, id}, state) do
    IO.inspect "fail #{id}"
    {new_dl, new_q} =
      pop_next(state.queued, state.downloading, id)

    {:noreply, %__MODULE__{ state |
                            :downloading =>  new_dl,
                            :queued => new_q,
                            :failed => MapSet.put(state.failed, id)
                          }}
  end

  def handle_info({:upload_success, id}, state) do
    IO.inspect "uldone #{id}"
    {:noreply, %__MODULE__{ state |
                            :uploading => MapSet.delete(state.uploading, id),
                            :finished => MapSet.put(state.finished, id)
                          }}
  end

  def handle_info({:upload_failure, id}, state) do
    IO.inspect "ulfail #{id}"
    {:noreply, %__MODULE__{ state |
                            :uploading => MapSet.delete(state.uploading, id),
                            :uploads_failed => MapSet.put(state.uploads_failed, id)
                          }}
  end

  defp pop_next(queued, downloading, id) do
    case :queue.out(queued) do
      {:empty, q} ->
        {MapSet.delete(downloading, id), q}
      {{:value, {next_id, {arg, dest}}}, q} ->
        {MapSet.delete(downloading, id) |> run_job(next_id, arg, dest), q}
    end
  end

  defp run_job(downloading, id, arg, dest) do
    {:ok, _pid} = DynamicSupervisor.start_child(Hatoba.MonitorSupervisor, {Hatoba.Download, [self(), id, arg, dest]})

    IO.puts "Download: #{id}"
    Hatoba.Download.start(id)
    MapSet.put(downloading, id)
  end

  defp start_upload(uploading, id, dl) do
    {:ok, _pid} = DynamicSupervisor.start_child(Hatoba.MonitorSupervisor, {Hatoba.Upload, [self(), id, dl]})

    IO.puts "Upload: #{id}"
    Hatoba.Upload.start(id)
    MapSet.put(uploading, id)
  end
end
