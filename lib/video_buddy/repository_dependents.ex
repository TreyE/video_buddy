defmodule VideoBuddy.RepositoryDependents do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    import Supervisor.Spec
    children = [
      # Start the endpoint when the application starts
      supervisor(VideoBuddyWeb.Endpoint, []),
      worker(VideoBuddyYoutube.AuthTokenManager, []),
      worker(VideoBuddyYoutube.UploadWorkerManager, []),
      worker(VideoBuddyYoutube.UploadScheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.init(children, strategy: :one_for_one)
  end
end
