defmodule Hatoba.Queue do
  use GenServer

  defstruct downloading: %{},
    finished: %{},
    failed: %{},
    queued: :queue.from_list([]),
    next_id: 0

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: :download_queue)
  end

  def status do
    GenServer.call(:download_queue, {:status})
  end

  def enqueue(arg) when is_list(arg) do
    Enum.each(arg, fn(a) ->
      GenServer.call(:download_queue, {:enqueue, a})
    end)
  end

  def enqueue(arg) do
    GenServer.call(:download_queue, {:enqueue, arg})
  end

  def clear do
    GenServer.call(:download_queue, {:clear})
  end

  ## GenServer

  def init(:ok), do: {:ok, %__MODULE__{}}

  def handle_call({:status}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:clear}, _from, state) do
    {:reply, :ok, %__MODULE__{next_id: state.next_id}}
  end

  def handle_call({:enqueue, arg}, _from, %__MODULE__{downloading: downloading, queued: queued, next_id: id} = state) do
    {:ok, _pid} = DynamicSupervisor.start_child(Hatoba.MonitorSupervisor, {Hatoba.Download, [self(), id, arg]})

    IO.inspect "queue #{arg}"

    {new_dl, new_q} = if Kernel.map_size(downloading) >= 10 do
      {downloading, :queue.in({id, 0}, queued)}
    else
      {run_job(downloading, id), queued}
    end

    {:reply, id, %__MODULE__{ state |
                              downloading: new_dl,
                              queued: new_q,
                              next_id: id + 1 }}
  end

  def move_and_dequeue(state, key, id) do
    {new_dl, new_q} =
      case :queue.out(state.queued) do
        {:empty, q} ->
          {Map.delete(state.downloading, id), q}
        {{:value, {next_id, _}}, q} ->
          {run_job(state.downloading, next_id) |> Map.delete(id), q}
      end

    IO.inspect id
    IO.inspect state.downloading
    IO.inspect new_dl
    new_map = Map.get(state, key) |> Map.put(id, true)
    new_state = Map.put(state, key, new_map)
    {:noreply, %__MODULE__{ new_state |
                            :downloading =>  new_dl,
                            :queued => new_q
                          }}
  end

  def handle_info({:download_success, id}, state) do
    IO.inspect "done #{id}"
    move_and_dequeue(state, :finished, id)
  end

  def handle_info({:download_failure, id}, state) do
    IO.inspect "fail #{id}"
    move_and_dequeue(state, :failed, id)
  end

  defp run_job(downloading, id) do
    Hatoba.Download.start(id)
    Map.put(downloading, id, true)
  end
end
