defmodule ErrorMessageShorts do
  @moduledoc File.read!("./README.md")
  alias ErrorMessageShorts.CommonParams

  @type code :: atom()
  @type message :: binary()
  @type details :: map() | nil

  @type error_message :: %{
    optional(any()) => any(),
    code: code(),
    message: message(),
    details: details()
  }

  @type params :: map() | keyword()
  @type replacement :: function() | term()

  @type operation :: :=~ | :=== | :< | :> | :<= | :>= | :eq | :lt | :gt | :lte | :gte
  @type precision :: :microsecond | :millisecond | :second

  @logger_prefix "ErrorMessageShorts"

  @app :error_message_shorts

  @default_code Application.compile_env(@app, :code, :internal_server_error)
  @default_message Application.compile_env(@app, :message, "oops something unexpected happened, please try again in a few minutes")

  @doc """
  Returns an error message map.

  ### Examples

      iex> ErrorMessageShorts.to_map(%{code: :not_found, message: "no records found", details: %{id: 1}})
      %{code: :not_found, message: "no records found", details: %{id: 1}}

      iex> ErrorMessageShorts.to_map(%{code: :not_found, message: "no records found"})
      %{code: :not_found, message: "no records found", details: nil}

      iex> ErrorMessageShorts.to_map(:not_found, "no records found", %{id: 1})
      %{code: :not_found, message: "no records found", details: %{id: 1}}

      iex> ErrorMessageShorts.to_map("no records found")
      %{code: :internal_server_error, details: nil, message: "no records found"}

      iex> ErrorMessageShorts.to_map(:invalid_term)
      %{
        code: :internal_server_error,
        details: nil,
        message: "oops something unexpected happened, please try again in a few minutes"
      }
  """
  @spec to_map(code(), message(), details()) :: error_message()
  def to_map(code, message, details) do
    %{
      code: code || @default_code,
      message: message || @default_message,
      details: details
    }
  end

  @spec to_map(
    binary() |
    error_message() |
    %{optional(any()) => any(), code: code(), message: message()} |
    term()
  ) :: error_message()
  def to_map(message) when is_binary(message) do
    to_map(nil, message, nil)
  end

  def to_map(%{code: _, message: _, details: _} = error_message) do
    error_message
  end

  def to_map(%{code: _, message: _} = error_message) do
    Map.put(error_message, :details, nil)
  end

  def to_map(term) do
    ErrorMessageShorts.Logger.warn(
      @logger_prefix,
      """
      Did not receive a valid error message, expected one of:

      `binary()`
      `%{code: atom(), message: binary(), details: nil | map()}`
      `%{code: atom(), message: binary()}`

      got:

      #{inspect(term, pretty: true)}
      """
    )

    to_map(@default_message)
  end

  @doc """
  Changes error message `code`, `message` and `details`.

  ### Examples

      iex> ErrorMessageShorts.change(
      ...>   %{
      ...>     code: :not_found,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{not_found: :service_unavailable},
      ...>     message: %{"no records" => %{=~: "service unavailable, please try again later"}},
      ...>   }
      ...> )
      %{code: :service_unavailable, message: "service unavailable, please try again later", details: %{id: 1}}
  """
  @spec change(
    term() | error_message(),
    params(),
    replacement()
  ) :: error_message()
  def change(term, params, replacement) do
    term
    |> to_map()
    |> CommonParams.change(params, replacement)
  end

  @doc """
  Changes error message `code`, `message` and `details`.

  ### Examples

      iex> ErrorMessageShorts.change(
      ...>   %{
      ...>     code: :not_found,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{not_found: :service_unavailable},
      ...>     message: %{"no records" => %{=~: "service unavailable, please try again later"}},
      ...>   }
      ...> )
      %{code: :service_unavailable, message: "service unavailable, please try again later", details: %{id: 1}}
  """
  @spec change(
    term() | error_message(),
    params()
  ) :: error_message()
  def change(term, params) do
    term
    |> to_map()
    |> CommonParams.change(
      code: params[:code] || [],
      message: params[:message] || [],
      details: params[:details] || []
    )
  end
end
