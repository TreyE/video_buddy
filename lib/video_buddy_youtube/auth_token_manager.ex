defmodule  VideoBuddyYoutube.AuthTokenManager do
  use GenServer

  defmodule State do
    defstruct [
      token: :no_token,
      client_id: nil,
      refresh_token: nil,
      client_secret: nil
    ]

    def new() do
      %__MODULE__{
        client_id: VideoBuddyYoutube.Config.client_id(),
        client_secret: VideoBuddyYoutube.Config.client_secret(),
        refresh_token: VideoBuddyYoutube.Config.refresh_token()
      }
    end

    def token(%__MODULE__{token: {tok_val, _exp_in}}) do
      tok_val
    end

    def set_token(state, auth_token, exp_in) do
      now_ts = DateTime.to_unix(DateTime.utc_now())
      %__MODULE__{state | token: {auth_token, exp_in + now_ts}}
    end

    def token_expired(%__MODULE__{token: :no_token}) do
      true
    end

    def token_expired(%__MODULE__{token: {_, exp_at}}) do
      now_ts = DateTime.to_unix(DateTime.utc_now())
      ((exp_at - now_ts) < 60)
    end
  end

  defmodule Requestor do
    use Tesla

    adapter :hackney

    plug Tesla.Middleware.BaseUrl, "https://www.googleapis.com"
    plug Tesla.Middleware.Headers, %{ 'user-agent': "Elixir" }
    plug Tesla.Middleware.DecodeJson
    plug Tesla.Middleware.FormUrlencoded

    def request_new_token(state) do
      resp = post(
        "/oauth2/v4/token",
        %{
           client_id: state.client_id,
           client_secret: state.client_secret,
           refresh_token: state.refresh_token,
           grant_type: "refresh_token"
        }
      )
      json = resp.body
      exp_in = Map.fetch!(json, "expires_in")
      new_token = Map.fetch!(json, "access_token")
      VideoBuddyYoutube.AuthTokenManager.State.set_token(state, new_token, exp_in)
    end
  end

  def init([]) do
    {:ok, VideoBuddyYoutube.AuthTokenManager.State.new()}
  end

  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_auth_token() do
    GenServer.call(__MODULE__, :get_auth_token)
  end

  def handle_call(:get_auth_token, _from, state) do
    case State.token_expired(state) do
      false -> {:reply, VideoBuddyYoutube.AuthTokenManager.State.token(state), state}
      _ ->
        new_state = get_token_using_state(state)
        {:reply, VideoBuddyYoutube.AuthTokenManager.State.token(new_state), new_state}
    end
  end

  defp get_token_using_state(state) do
    Requestor.request_new_token(state)
  end
end
