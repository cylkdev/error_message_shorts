defmodule ErrorMessageShorts do
  @moduledoc File.read!("./README.md")

  @type code :: atom()
  @type message :: binary()
  @type details :: map() | nil

  @type error_message :: %{
    code: code(),
    message: message(),
    details: details()
  }

  @doc """
  Changes error message `code`, `message` and `details`.

  ### Examples

      iex> ErrorMessageShorts.change(
      ...>   %{
      ...>     code: :not_found,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   {
      ...>     %{code: :not_found},
      ...>     fn error_message -> %{error_message | code: :service_unavailable} end
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "no records found",
        details: %{id: 1}
      }

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
      %{
        code: :service_unavailable,
        message: "service unavailable, please try again later",
        details: %{id: 1}
      }
  """
  @spec change(term(), any(), keyword()) :: error_message()
  @spec change(term(), any()) :: error_message()
  def change(term, params, opts \\ []) do
    term
    |> convert_to_error_message()
    |> SubstituteX.change(params, opts)
  end

  @doc """
  Returns an error message map.

  ### Examples

      iex> ErrorMessageShorts.convert_to_error_message(%{code: :not_found, message: "no records found", details: %{id: 1}})
      %{code: :not_found, message: "no records found", details: %{id: 1}}

      iex> ErrorMessageShorts.convert_to_error_message(%{code: :not_found, message: "no records found"})
      %{code: :not_found, message: "no records found", details: nil}

      iex> ErrorMessageShorts.convert_to_error_message(:not_found, "no records found", %{id: 1})
      %{code: :not_found, message: "no records found", details: %{id: 1}}

      iex> ErrorMessageShorts.convert_to_error_message("no records found")
      %{code: :internal_server_error, details: nil, message: "no records found"}
  """
  @spec convert_to_error_message(code(), message(), details()) :: error_message()
  def convert_to_error_message(code, message, details) do
    Map.merge(default_error_message(), %{
      code: code,
      message: message,
      details: details
    })
  end

  @doc """
  Returns an error message map.

  ### Examples

      iex> ErrorMessageShorts.convert_to_error_message("an unexpected error occurred")
      %{code: :internal_server_error, message: "an unexpected error occurred", details: nil}

      iex> ErrorMessageShorts.convert_to_error_message(%{message: "an unexpected error occurred"})
      %{code: :internal_server_error, message: "an unexpected error occurred", details: nil}

      iex> ErrorMessageShorts.convert_to_error_message(%{code: :not_found, message: "no records found"})
      %{code: :not_found, message: "no records found", details: nil}

      iex> ErrorMessageShorts.convert_to_error_message(%{code: :not_found, message: "no records found", details: %{id: 1}})
      %{code: :not_found, message: "no records found", details: %{id: 1}}

      iex> ErrorMessageShorts.convert_to_error_message("no records found")
      %{code: :internal_server_error, details: nil, message: "no records found"}
  """
  @spec convert_to_error_message(
    binary() |
    %{code: code(), message: message(), details: details()} |
    %{code: code(), message: message()} |
    %{message: message()}
  ) :: error_message()
  def convert_to_error_message(message) when is_binary(message) do
    convert_to_error_message(:internal_server_error, message, nil)
  end

  def convert_to_error_message(%{code: code, message: message, details: details}) do
    convert_to_error_message(code, message, details)
  end

  def convert_to_error_message(%{code: code, message: message}) do
    convert_to_error_message(code, message, nil)
  end

  def convert_to_error_message(%{message: message}) do
    convert_to_error_message(:internal_server_error, message, nil)
  end

  def convert_to_error_message(term) do
    raise ArgumentError, """
    Expected one of:

    `binary()`
    `%{code: atom(), message: binary(), details: nil | map()}`
    `%{code: atom(), message: binary()}`
    `%{message: binary()}`

    got:

    #{inspect(term, pretty: true)}
    """
  end

  defp default_error_message do
    %{
      code: :internal_server_error,
      message: "oops something unexpected happened, please try again in a few minutes",
      details: nil
    }
  end
end
