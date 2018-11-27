defmodule VideoBuddyYoutube.UploadWorkerManager do
  @moduledoc """
  Tracks who is working a certain YouTube upload.
  """

  @spec filter_assigned_uploads([upload_id()]) :: [upload_id()]
  def filter_assigned_uploads(upload_id_list) do
    GenServer.call(__MODULE__, :cull)
    working_ids = GenServer.call(__MODULE__, :ids_being_worked)
    Enum.filter(
      upload_id_list,
      fn(uid) ->
        !Enum.member?(working_ids, uid)
      end
    )
  end

  def register_upload_worker(upload_id, pid) do
    GenServer.call(__MODULE__, {:register_worker, upload_id, pid})
  end

  use GenServer

  @type upload_id :: term()
  @type state :: %{upload_id() => pid()}

  @spec init([]) :: {:ok, state()}
  def init([]) do
    {:ok, Map.new()}
  end

  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec handle_call(any(), any(), state()) :: {:reply, :ok, state()}
  def handle_call(:cull, _, state) do
    {:reply, :ok, cull_dead_workers(state)}
  end

  def handle_call(:ids_being_worked, _, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:who_is_working, upload_id}, _, state) do
    case Map.get(state, upload_id, nil) do
       nil -> {:reply, :nobody, state}
       a_pid -> {:reply, {:pid, a_pid}, state}
    end
  end

  def handle_call({:register_worker, upload_id, pid}, _, state) do
    case Map.has_key?(state, upload_id) do
      false -> {:reply, :ok, Map.put(state, upload_id, pid)}
      _ -> {:reply, {:error, {:has_worker, Map.fetch!(state, upload_id)}}, state}
    end
  end

  defp cull_dead_workers(state) do
    :maps.filter(
      fn _, v ->
        Process.alive?(v)
      end,
    state)
  end
end
