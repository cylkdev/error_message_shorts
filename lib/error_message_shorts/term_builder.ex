defmodule ErrorMessageShorts.TermBuilder do
  @moduledoc """
  Transform terms by parameters that define a matching pattern.
  """

  @type string_comparison_operator :: :=~
  @type equals_to_comparison_operator :: :=== | :eq
  @type greater_than_comparison_operator :: :> | :gt
  @type less_than_comparison_operator :: :< | :lt
  @type greater_than_or_equal_to_comparison_operator :: :>= | :gte
  @type less_than_or_equal_to_comparison_operator :: :<= | :lte

  @type comparison_operators :: (
    string_comparison_operator() |
    equals_to_comparison_operator() |
    greater_than_comparison_operator() |
    less_than_comparison_operator() |
    greater_than_or_equal_to_comparison_operator() |
    less_than_or_equal_to_comparison_operator()
  )

  @type pattern :: binary() | atom() | Regex.t()
  @type params :: ErrorMessageShorts.params()
  @type replacement :: ErrorMessageShorts.replacement()

  @comparison_string_operators [:=~]
  @comparison_equal_operators [:===, :eq]
  @comparison_greater_than_operators [:>, :gt]
  @comparison_less_than_operators [:<, :lt]
  @comparison_greater_than_or_equal_to_operators [:>=, :gte]
  @comparison_less_than_or_equal_to_operators [:<=, :lte]

  @comparison_operators (
    @comparison_string_operators ++
    @comparison_equal_operators ++
    @comparison_greater_than_operators ++
    @comparison_less_than_operators ++
    @comparison_greater_than_or_equal_to_operators ++
    @comparison_less_than_or_equal_to_operators
  )

  @doc """
  Returns true if the left matches the right.

  ### Examples

      iex> ErrorMessageShorts.TermBuilder.compare?("message", ~r|message|)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?("message", "message")
      true

      iex> ErrorMessageShorts.TermBuilder.compare?("message", :message)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(:message, "message")
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(:message, :message)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{name: "example"}, %{name: "example"})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{name: "example", posts: [%{body: "test"}]}, %{name: "example"})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{comments: [%{body: "this is an example"}]}, %{comments: [%{body: "this is an example"}]})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?([%{name: "example"}], [%{name: "example"}])
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{name: "example"}, %{name: %{=~: "example"}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{name: "example"}, %{name: %{===: "example"}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{name: "example"}, %{name: %{=~: ~r|ex|}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{likes: 100}, %{likes: 100})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{likes: 100}, %{likes: %{>=: 90}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{likes: 100}, %{likes: %{<=: 110}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{likes: 100}, %{likes: %{===: 100}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{likes: 100}, %{likes: ~r|100|})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{inserted_at: ~U[2024-07-31 04:00:00Z]}, %{inserted_at: %{eq: ~U[2024-07-31 04:00:00Z]}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{inserted_at: ~U[2024-07-31 04:00:00Z]}, %{inserted_at: %{===: ~U[2024-07-31 04:00:00Z]}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{inserted_at: ~U[2024-07-31 04:10:00Z]}, %{inserted_at: %{gt: ~U[2024-07-31 04:00:00Z]}})
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(%{inserted_at: ~U[2024-07-31 04:00:00Z]}, %{inserted_at: %{lt: ~U[2024-07-31 04:10:00Z]}})
      true
  """
  @spec compare?(term(), params()) :: boolean()
  def compare?(enum, params) when is_map(params) and not is_struct(params) do
    compare?(enum, Map.to_list(params))
  end

  def compare?(term, {operator, pattern}) when operator in @comparison_operators do
    compare?(term, operator, pattern)
  end

  def compare?(enum, {key, value}) when is_list(enum) or is_map(enum) do
    compare?(enum[key], value)
  end

  def compare?(_enum, []) do
    true
  end

  def compare?(enum, [{key, value} | []] = _) do
    compare?(enum, {key, value})
  end

  def compare?([head | tail], [next | todo]) do
    compare?(head, next) and compare?(tail, todo)
  end

  def compare?(string, %Regex{} = regex) do
    Regex.match?(regex, to_string(string))
  end

  def compare?(left, right) when is_atom(left) and is_binary(right) do
    to_string(left) === right
  end

  def compare?(left, right) when is_binary(left) and is_atom(right) do
    left === to_string(right)
  end

  def compare?(left, right) do
    left === right
  end

  @doc """
  Returns true if the `comparison` of the `left` and `right` is `true`.

  ### Examples

      iex> ErrorMessageShorts.TermBuilder.compare?(:message, :===, :message)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?("message", :===, "message")
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(:message, :===, "message")
      true

      iex> ErrorMessageShorts.TermBuilder.compare?("message", :===, :message)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?(:message, :=~, ~r|message|)
      true

      iex> ErrorMessageShorts.TermBuilder.compare?("message", :=~, ~r|message|)
      true
  """
  @spec compare?(
    term(),
    comparison_operators(),
    term()
  ) :: term()
  def compare?(term, :=~, %Regex{} = regex) do
    Regex.match?(regex, to_string(term))
  end

  def compare?(left, comparison, %DateTime{} = right) when comparison in [:===, :eq] do
    DateTime.compare(left, right) === :eq
  end

  def compare?(left, comparison, %DateTime{} = right) when comparison in [:>, :gt] do
    DateTime.compare(left, right) === :gt
  end

  def compare?(left, comparison, %DateTime{} = right) when comparison in [:<, :lt] do
    DateTime.compare(left, right) === :lt
  end

  def compare?(_left, comparison, %DateTime{} = _right) do
    raise ArgumentError, "Expected one of [:===, :eq, :>, :gt, :<, :lt], got: #{inspect(comparison)}"
  end

  def compare?(string, :=~, term) do
    string =~ term
  end

  def compare?(left, _comparison, %Regex{} = regex) do
    compare?(left, regex)
  end

  def compare?(left, comparison, right) when comparison in [:===, :eq] do
    compare?(left, right)
  end

  def compare?(left, comparison, right) when comparison in [:>, :gt] do
    left > right
  end

  def compare?(left, comparison, right) when comparison in [:<, :lt] do
    left < right
  end

  def compare?(left, comparison, right) when comparison in [:>=, :gte] do
    left >= right
  end

  def compare?(left, comparison, right) when comparison in [:<=, :lte] do
    left <= right
  end

  @doc """
  Returns a new term if the `pattern` matches the `term` based on the `comparison` operator.

  ### Examples

      iex> ErrorMessageShorts.TermBuilder.change("message", %{message: "change"})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", %{message: %{===: fn -> "change" end}})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", %{"message" => %{=~: fn -> "change" end}})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", %{~r|message| => fn -> "change" end})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", %{~r|message| => %{===: fn -> "change" end}})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", %{~r|message| => %{=~: fn -> "change" end}})
      "change"
  """
  @spec change(
    term(),
    params() |
    {pattern(), params() | replacement()} |
    list({pattern(), params() | replacement()}) |
    list(params())
  ) :: term()
  def change(term, params) when is_map(params) do
    change(term, Map.to_list(params))
  end

  def change(term, {pattern, params}) when is_map(params) do
    change(term, pattern, Map.to_list(params))
  end

  def change(term, {pattern, params}) when is_list(params) do
    change(term, pattern, params)
  end

  def change(term, {pattern, replacement}) do
    change(term, :===, pattern, replacement)
  end

  def change(term, []) do
    term
  end

  def change(term, [next | todo]) do
    term
    |> change(next)
    |> change(todo)
  end

  @doc """
  Returns a new term if the `pattern` matches the `term` based on the `comparison` operator.

  ### Examples

      iex> ErrorMessageShorts.TermBuilder.change("message", :message, {:===, "change"})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", :message, {:===, fn -> "change" end})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", "message", {:=~, fn -> "change" end})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", ~r|message|, fn -> "change" end)
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", ~r|message|, {:===, fn -> "change" end})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", ~r|message|, {:=~, fn -> "change" end})
      "change"

      iex> ErrorMessageShorts.TermBuilder.change(%{name: "example"}, %{name: "example"}, fn -> %{body: "changed"} end)
      %{body: "changed"}

      iex> ErrorMessageShorts.TermBuilder.change(%{name: "example"}, %{name: "example"}, %{body: "changed"})
      %{body: "changed"}

      iex> ErrorMessageShorts.TermBuilder.change(%{name: "example"}, :*, %{body: "changed"})
      %{body: "changed"}

      iex> ErrorMessageShorts.TermBuilder.change(%{name: "example"}, %{}, %{body: "changed"})
      %{body: "changed"}
  """
  @spec change(
    term(),
    pattern(),
    {comparison_operators(), replacement()} |
    list({comparison_operators(), replacement()}) |
    term()
  ) :: term()
  def change(term, :*, func) when is_function(func, 1) do
    func.(term)
  end

  def change(_term, :*, func) when is_function(func, 0) do
    func.()
  end

  def change(_term, :*, replacement) do
    replacement
  end

  def change(term, pattern, {comparison, replacement}) do
    change(term, comparison, pattern, replacement)
  end

  def change(term, _pattern, []) do
    term
  end

  def change(term, pattern, [next | todo]) do
    term
    |> change(pattern, next)
    |> change(pattern, todo)
  end

  def change(term, params, func) when is_function(func) do
    if compare?(term, params) do
      if is_function(func, 1), do: func.(term), else: func.()
    else
      term
    end
  end

  def change(term, params, replacement) do
    if compare?(term, params) do
      replacement
    else
      term
    end
  end

  @doc """
  Returns a new term if the `pattern` matches the `term` based on the `comparison` operator.

  ### Examples

      iex> ErrorMessageShorts.TermBuilder.change("message", :eq, "message", fn -> "change" end)
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", :===, "message", fn -> "change" end)
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", :=~, "message", fn -> "change" end)
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", :=~, ~r|message|, fn -> "change" end)
      "change"

      iex> ErrorMessageShorts.TermBuilder.change("message", :===, ~r|message|, fn -> "change" end)
      "change"
  """
  @spec change(
    term(),
    comparison_operators(),
    pattern(),
    function() | term()
  ) :: term()
  def change(term, comparison, pattern, func) when is_function(func) do
    if compare?(term, comparison, pattern) do
      if is_function(func, 1), do: func.(term), else: func.()
    else
      term
    end
  end

  def change(term, comparison, pattern, replacement) do
    if compare?(term, comparison, pattern) do
      replacement
    else
      term
    end
  end
end
