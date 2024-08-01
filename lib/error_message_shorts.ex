defmodule ErrorMessageShorts do
  @moduledoc File.read!("./README.md")
  alias ErrorMessageShorts.TermBuilder

  @type code :: atom()
  @type message :: binary()
  @type details :: map() | nil

  @type error_message :: %{
    optional(any()) => any(),
    code: code(),
    message: message(),
    details: details()
  }

  @type pattern :: binary() | atom() | Regex.t()
  @type params :: map() | list()
  @type replacement :: function() | term()

  @app :error_message_shorts

  @default_code Application.compile_env(@app, :code, :internal_server_error)
  @default_message Application.compile_env(@app, :message, "oops something unexpected happened, please try again in a few minutes")

  @doc """
  Returns an error message map.

  ### Examples

      iex> ErrorMessageShorts.to_map(:not_found, "no records found", %{id: 1})
      %{code: :not_found, details: %{id: 1}, message: "no records found"}

      iex> ErrorMessageShorts.to_map("no records found")
      %{code: :internal_server_error, details: nil, message: "no records found"}

      iex> ErrorMessageShorts.to_map(%{code: :not_found, message: "no records found", details: %{id: 1}})
      %{code: :not_found, details: %{id: 1}, message: "no records found"}

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

  @spec to_map(term()) :: error_message()
  def to_map(message) when is_binary(message) do
    to_map(nil, message, nil)
  end

  def to_map(%{code: _, message: _, details: _} = error_message) do
    error_message
  end

  def to_map(%{code: _, message: _} = error_message) do
    Map.put(error_message, :details, nil)
  end

  def to_map(_term) do
    to_map(@default_message)
  end

  @doc """
  Converts a term to an error message map and replaces the `code`, `message` and
  details with the `replacement` if a match is found.

  ### Examples

      iex> ErrorMessageShorts.normalize(
      ...>   %{
      ...>     code: :request_timeout,
      ...>     message: "no records found"
      ...>   },
      ...>   %{
      ...>     code: %{request_timeout: :service_unavailable},
      ...>     message: %{"no records found" => "oops something is missing"},
      ...>     details: {%{id: 1}, fn details -> %{input: %{user_id: details.id}} end}
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "oops something is missing",
        details: nil
      }

      iex> ErrorMessageShorts.normalize(
      ...>   %{
      ...>     code: :request_timeout,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{request_timeout: :service_unavailable},
      ...>     message: %{"no records found" => "oops something is missing"},
      ...>     details: [{%{id: 1}, fn details -> %{input: %{user_id: details.id}} end}]
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "oops something is missing",
        details: %{input: %{user_id: 1}}
      }

      iex> ErrorMessageShorts.normalize(
      ...>   %{
      ...>     code: :request_timeout,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{request_timeout: :service_unavailable},
      ...>     message: %{"no records found" => "user %{id} not found"},
      ...>     details: [{%{id: 1}, fn details -> %{input: %{user_id: details.id}} end}],
      ...>     replacements: fn %{details: %{input: %{user_id: user_id}}} -> %{"id" => to_string(user_id)} end
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "user 1 not found",
        details: %{input: %{user_id: 1}}
      }

      iex> ErrorMessageShorts.normalize(
      ...>   %{
      ...>     code: :request_timeout,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{request_timeout: :service_unavailable},
      ...>     message: %{"no records found" => "user %{id} not found"},
      ...>     details: [{%{id: 1}, fn details -> %{input: %{user_id: details.id}} end}],
      ...>     replacements: %{"id" => "1"}
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "user 1 not found",
        details: %{input: %{user_id: 1}}
      }

      iex> ErrorMessageShorts.normalize(
      ...>   %{
      ...>     code: :request_timeout,
      ...>     message: "no records found",
      ...>     details: %{id: 1}
      ...>   },
      ...>   %{
      ...>     code: %{request_timeout: :service_unavailable},
      ...>     message: %{"no records found" => "user not found"},
      ...>     details: {:*, fn -> %{input: %{user_id: 1}} end}
      ...>   }
      ...> )
      %{
        code: :service_unavailable,
        message: "user not found",
        details: %{input: %{user_id: 1}}
      }
  """
  @spec normalize(error_message() | term(), params()) :: error_message()
  def normalize(%{code: code, message: message, details: details} = error_message, params) when is_map(params) do
    code = TermBuilder.change(code, params[:code] || [])
    message = TermBuilder.change(message, params[:message] || [])
    details = apply_changes(params[:details] || [], details)

    error_message =
      %{
        error_message |
        code: code,
        message: message,
        details: details
      }

    apply_replacements(error_message, params[:replacements])
  end

  def normalize(error_message, params) when is_list(params) do
    Enum.reduce(params, error_message, &normalize(&2, &1))
  end

  def normalize(term, params) do
    term |> to_map() |> normalize(params)
  end

  defp apply_replacements(error_message, nil) do
    error_message
  end

  defp apply_replacements(error_message, func) when is_function(func, 1) do
    apply_replacements(error_message, func.(error_message))
  end

  defp apply_replacements(error_message, func) when is_function(func, 0) do
    apply_replacements(error_message, func.())
  end

  defp apply_replacements(%{message: message} = error_message, params) do
    %{error_message | message: reduce_template_literals(params, message)}
  end

  defp reduce_template_literals(params, string) do
    Enum.reduce(params, string, &replace_template_literal/2)
  end

  defp replace_template_literal({pattern, replacement}, message) do
    String.replace(message, "%{#{pattern}}", replacement)
  end

  defp apply_changes(changes, term) do
    changes
    |> List.wrap()
    |> Enum.reduce(term, &reduce_change/2)
  end

  defp reduce_change({definition, replacement}, acc) do
    TermBuilder.change(acc, definition, replacement)
  end
end
