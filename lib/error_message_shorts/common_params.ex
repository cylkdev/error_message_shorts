defmodule ErrorMessageShorts.CommonParams do
  @moduledoc """
  This module provides a standardized api for matching and replacing terms.

  ### Match & Replace Parameters

  The parameters represents a pattern for performing a match and replacement operation on a term
  and can take one of the following structures:

    * `%{<pattern> => <replacement>}` - Replaces `value` with `replacement` if `pattern` equals `value`.

    * `%{<pattern> => %{<operation> => <replacement>}}` - Replaces `value` with `replacement` if the
      comparison between `value` and `pattern` using `operation` returns true.

    * `%{<key> => %{<pattern> => %{<operation> => <replacement>}}}` - Replaces value with `replacement`
      when the comparison between `value` and `pattern` using the `operation` specified under the nested
      `key` evaluates to true.
  """

  @type operation :: ErrorMessageShorts.operation()
  @type precision :: ErrorMessageShorts.precision()
  @type params :: ErrorMessageShorts.params()
  @type replacement :: ErrorMessageShorts.replacement()

  @doc """
  Compares two terms, `left` and `right`, using a specified comparison operation.

  Returns `true` if the evaluation of `<left> <operation> <right>`, for eg. `1 === 1`, `1 >= 1`, and `"example" =~ "ex"`.

  ### Parameters

    * `left`: Term used during the comparison.

    * `operation`: An atom that specifies how `left` and `right` should be compared, Can be one of the following:

        * `:=~` - When used with two strings, `:=~ `checks if the right-hand side string is a substring of the
          left-hand side string. When the right-hand side is a regular expression (a pattern enclosed in ~r//),
          `:=~` checks if the pattern matches any part of the left-hand side string.

        * `:===` - Checks whether `left` and `right` values are both equal and of the same type.

        * `:<` - Checks if the `left` is less than the `right` side value. This works for `integer`, `DateTime`
          structs and `NaiveDateTime` structs.

        * `:>` - Checks if the `left` is greater than the `right` side value. This works for `integer`, `DateTime`
          structs and `NaiveDateTime` structs.

        * `:<=` - Checks if the `left` is equal to or less than the `right` side value. This works for `integer`,
          `DateTime` structs and `NaiveDateTime` structs.

        * `:>=` - Checks if the `left` is equal to or greater than the `right` side value. This works for `integer`,
          `DateTime` structs and `NaiveDateTime` structs.

        * `:eq` - See documentation on `:===` operation.

        * `:lt` - See documentation on `:<` operation.

        * `:gt` - See documentation on `:>` operation.

        * `:lte` - See documentation on `:<=` operation.

        * `:gte` - See documentation on `:>=` operation.


  When both `left` and `right` are `DateTime` or `NaiveDateTime` structs, you can pass a tuple
  `{operation(), precision()}` where:

    * `operation`: An atom representing the comparison operation.

    * `precision`: An atom indicating the precision level to truncate the `left` and `right` timestamps
      (e.g., `:microsecond`, `:millisecond`, `:second`) before evaluation.

  ### Examples

      iex> ErrorMessageShorts.CommonParams.compare?(~U[2024-08-04 10:59:11.560770Z], {:===, :second}, ~U[2024-08-04 10:59:11.100000Z])
      true

      iex> ErrorMessageShorts.CommonParams.compare?(~U[2024-08-04 00:00:00Z], :===, ~U[2024-08-04 00:00:00Z])
      true

      iex> ErrorMessageShorts.CommonParams.compare?(~N[2024-08-04 10:59:11.560770Z], {:===, :second}, ~N[2024-08-04 10:59:11.100000Z])
      true

      iex> ErrorMessageShorts.CommonParams.compare?(~N[2024-08-04 00:00:00Z], :===, ~N[2024-08-04 00:00:00Z])
      true
  """
  @spec compare?(
    left :: DateTime.t() | NaiveDateTime.t() | term(),
    operation_or_operation_precision_tuple :: operation() | {operation(), precision()},
    right :: DateTime.t() | NaiveDateTime.t() | term()
  ) :: boolean()
  def compare?(left, operation_or_operation_precision_tuple, right)

  def compare?(%NaiveDateTime{} = left, {operation, precision}, %NaiveDateTime{} = right) do
    left = NaiveDateTime.truncate(left, precision)
    right = NaiveDateTime.truncate(right, precision)

    compare?(left, operation, right)
  end

  def compare?(%NaiveDateTime{} = left, :===, %NaiveDateTime{} = right), do: NaiveDateTime.compare(left, right) === :eq
  def compare?(%NaiveDateTime{} = left, :<, %NaiveDateTime{} = right), do: NaiveDateTime.compare(left, right) === :lt
  def compare?(%NaiveDateTime{} = left, :>, %NaiveDateTime{} = right), do: NaiveDateTime.compare(left, right) === :gt
  def compare?(%NaiveDateTime{} = left, :<=, %NaiveDateTime{} = right), do: compare?(left, :<, right) || compare?(left, :===, right)
  def compare?(%NaiveDateTime{} = left, :>=, %NaiveDateTime{} = right), do: compare?(left, :>, right) || compare?(left, :===, right)
  def compare?(%NaiveDateTime{} = left, :eq, %NaiveDateTime{} = right), do: compare?(left, :===, right)
  def compare?(%NaiveDateTime{} = left, :lt, %NaiveDateTime{} = right), do: compare?(left, :<, right)
  def compare?(%NaiveDateTime{} = left, :gt, %NaiveDateTime{} = right), do: compare?(left, :>, right)
  def compare?(%NaiveDateTime{} = left, :lte, %NaiveDateTime{} = right), do: compare?(left, :<=, right)
  def compare?(%NaiveDateTime{} = left, :gte, %NaiveDateTime{} = right), do: compare?(left, :>=, right)

  def compare?(%DateTime{} = left, {operation, precision}, %DateTime{} = right) do
    left = DateTime.truncate(left, precision)
    right = DateTime.truncate(right, precision)

    compare?(left, operation, right)
  end

  def compare?(%DateTime{} = left, :===, %DateTime{} = right), do: DateTime.compare(left, right) === :eq
  def compare?(%DateTime{} = left, :<, %DateTime{} = right), do: DateTime.compare(left, right) === :lt
  def compare?(%DateTime{} = left, :>, %DateTime{} = right), do: DateTime.compare(left, right) === :gt
  def compare?(%DateTime{} = left, :<=, %DateTime{} = right), do: compare?(left, :<, right) || compare?(left, :===, right)
  def compare?(%DateTime{} = left, :>=, %DateTime{} = right), do: compare?(left, :>, right) || compare?(left, :===, right)
  def compare?(%DateTime{} = left, :eq, %DateTime{} = right), do: compare?(left, :===, right)
  def compare?(%DateTime{} = left, :lt, %DateTime{} = right), do: compare?(left, :<, right)
  def compare?(%DateTime{} = left, :gt, %DateTime{} = right), do: compare?(left, :>, right)
  def compare?(%DateTime{} = left, :lte, %DateTime{} = right), do: compare?(left, :<=, right)
  def compare?(%DateTime{} = left, :gte, %DateTime{} = right), do: compare?(left, :>=, right)

  def compare?(left, :===, right), do: left === right
  def compare?(left, :=~, right), do: left =~ right
  def compare?(left, :<, right), do: left < right
  def compare?(left, :>, right), do: left > right
  def compare?(left, :<=, right), do: left <= right
  def compare?(left, :>=, right), do: left >= right
  def compare?(left, :eq, right), do: compare?(left, :===, right)
  def compare?(left, :lt, right), do: compare?(left, :<, right)
  def compare?(left, :gt, right), do: compare?(left, :>, right)
  def compare?(left, :lte, right), do: compare?(left, :<=, right)
  def compare?(left, :gte, right), do: compare?(left, :>=, right)

  @doc """
  Returns `true` if the `value` matches the params.

  ### Examples

      # succeeds if one of the patterns on the right matches the left
      iex> ErrorMessageShorts.CommonParams.compare?("example", ["example"])
      true

      # succeeds if the right is contained in the left
      iex> ErrorMessageShorts.CommonParams.compare?(%{post: %{body: "example", likes: 10}}, %{post: %{body: "example"}})
      true

      # fails if the entire project on the right does not match the left
      iex> ErrorMessageShorts.CommonParams.compare?(%{post: %{body: "example"}}, %{post: %{body: "example", likes: 10}})
      false
  """
  @spec compare?(term(), map() | keyword()) :: term()
  def compare?(term, params) when is_map(params), do: compare?(term, Map.to_list(params))
  def compare?(term, params), do: traverse_match(term, params)

  defp traverse_match(term, {key, params}) when is_map(params) and not is_struct(params) do
    traverse_match(term, {key, Map.to_list(params)})
  end

  defp traverse_match([], _) do
    false
  end

  defp traverse_match([{_, _} | _] = keyword, {key, params}) do
    keyword
    |> Keyword.get(key)
    |> traverse_match(params)
  end

  defp traverse_match([head | tail], {key, params}) do
    traverse_match(head, {key, params}) && traverse_match(tail, {key, params})
  end

  defp traverse_match(map, {key, params}) when is_map(map) and not is_struct(map) do
    map
    |> Map.get(key)
    |> traverse_match(params)
  end

  defp traverse_match(_term, {_key, []}) do
    true
  end

  defp traverse_match(term, {key, [head | todo]}) do
    traverse_match(term, {key, head}) && traverse_match(term, {key, todo})
  end

  defp traverse_match(term, params) when is_map(params) do
    traverse_match(term, Map.to_list(params))
  end

  defp traverse_match(_term, []) do
    true
  end

  defp traverse_match(term, [head | todo]) do
    traverse_match(term, head) && traverse_match(term, todo)
  end

  defp traverse_match(term, {pattern, operation}) do
    compare?(term, operation, pattern)
  end

  defp traverse_match(term, pattern) do
    compare?(term, :===, pattern)
  end

  @doc """
  Replaces the `term` with `replacement` if it matches the parameters.

  ### Examples

      iex> ErrorMessageShorts.CommonParams.change("example", ["example"], "new_value")
      "new_value"

      iex> ErrorMessageShorts.CommonParams.change("example", ["example"], fn -> "new_value" end)
      "new_value"

      iex> ErrorMessageShorts.CommonParams.change(%{body: "example"}, %{body: "example"}, %{message: "example"})
      %{message: "example"}

  """
  @spec change(term(), params(), replacement()) :: term()
  def change(term, params, replacement) do
    if compare?(term, params) do
      resolve(replacement, term, params)
    else
      term
    end
  end

  @doc """
  Replaces a `value`, each `value` in a `list`, or the `value` associated with each `key` in an
  enumerable with the specified `replacement` if a match is found.

  ### Examples

      # returns existing value if match not found
      iex> ErrorMessageShorts.CommonParams.change("example", %{"not_a_match" => "new_value"})
      "example"

      # replace a string if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change("example", %{"example" => "new_value"})
      "new_value"

      # replace a string if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change("example", %{"example" => fn -> "new_value" end})
      "new_value"

      # replace a string if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change("example", %{"example" => fn _existing_value -> "new_value" end})
      "new_value"

      # replace a string if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change("example", %{"example" => fn _existing_value, _pattern -> "new_value" end})
      "new_value"

      # replace a string by string comparison
      iex> ErrorMessageShorts.CommonParams.change("example", %{"ex" => %{=~: "new_value"}})
      "new_value"

      # replace a string if the string matches the key regex
      iex> ErrorMessageShorts.CommonParams.change("example", %{~r|example| => %{=~: "new_value"}})
      "new_value"

      # explicit comparison fails because a string is not a regex struct
      iex> ErrorMessageShorts.CommonParams.change("example", %{~r|example| => %{===: "new_value"}})
      "example"

      # explicit comparison using `:eq` fails because a string is not a regex struct
      iex> ErrorMessageShorts.CommonParams.change("example", %{~r|example| => %{eq: "new_value"}})
      "example"

      # replace a integer if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => 2_000})
      2_000

      # replace a integer if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{===: 2_000}})
      2_000

      # replace a integer if the key is less than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{2_000 => %{<: 2_000}})
      2_000

      # replace a integer if the key is greater than the value
      iex> ErrorMessageShorts.CommonParams.change(2_000, %{1_000 => %{>: 1_000}})
      1_000

      # replace a integer if the key is equal to or less than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{<=: 2_000}})
      2_000

      # replace a integer if the key is equal to or greater than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{>=: 2_000}})
      2_000

      # replace a integer if it is equal to the key
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{eq: 2_000}})
      2_000

      # replace a integer if the key is less than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{2_000 => %{lt: 2_000}})
      2_000

      # replace a integer if the key is greater than the value
      iex> ErrorMessageShorts.CommonParams.change(2_000, %{1_000 => %{gt: 1_000}})
      1_000

      # replace a integer if the key is equal to or less than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{lte: 2_000}})
      2_000

      # replace a integer if the key is equal to or greater than the value
      iex> ErrorMessageShorts.CommonParams.change(1_000, %{1_000 => %{gte: 2_000}})
      2_000

      # replace the value of a key in a map
      iex> ErrorMessageShorts.CommonParams.change(%{message: "foo"}, %{message: %{"foo" => "bar"}})
      %{message: "bar"}

      # replace the values of keys in a list
      iex> ErrorMessageShorts.CommonParams.change([%{message: "foo"}], %{message: %{"foo" => "bar"}})
      [%{message: "bar"}]

      # replace the value of a key in a map by string comparison
      iex> ErrorMessageShorts.CommonParams.change(%{posts: [%{message: "foo"}, %{message: "qux"}]}, %{posts: %{message: %{"foo" => %{=~: "bar"}}}})
      %{posts: [%{message: "bar"}, %{message: "qux"}]}

      # replace the values of keys in a list by string comparison
      iex> ErrorMessageShorts.CommonParams.change([%{posts: [%{message: "foo"}, %{message: "qux"}]}], %{posts: %{message: %{"foo" => %{=~: "bar"}}}})
      [%{posts: [%{message: "bar"}, %{message: "qux"}]}]

      # replace a datetime timestamp by equal comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{===: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by precision
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{{:===, :second} => ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-05 00:00:00Z] => %{<: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-03 00:00:00Z] => %{>: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by equal to or less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{<=: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by equal to or greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{>=: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by equal comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{eq: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-05 00:00:00Z] => %{lt: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-03 00:00:00Z] => %{gt: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by equal to or less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{lte: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a datetime timestamp by equal to or greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~U[2024-08-04 00:00:00Z]}, %{inserted_at: %{~U[2024-08-04 00:00:00Z] => %{gte: ~U[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~U[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{===: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by precision
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{{:===, :second} => ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-05 00:00:00Z] => %{<: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-03 00:00:00Z] => %{>: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal to or less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{<=: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal to or greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{>=: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{eq: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-05 00:00:00Z] => %{lt: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-03 00:00:00Z] => %{gt: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal to or less than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{lte: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}

      # replace a naive datetime timestamp by equal to or greater than comparison
      iex> ErrorMessageShorts.CommonParams.change(%{inserted_at: ~N[2024-08-04 00:00:00Z]}, %{inserted_at: %{~N[2024-08-04 00:00:00Z] => %{gte: ~N[2024-08-01 00:00:00Z]}}})
      %{inserted_at: ~N[2024-08-01 00:00:00Z]}
  """
  @spec change(term(), map() | keyword()) :: term()
  def change(term, params) when is_map(params), do: change(term, Map.to_list(params))
  def change(term, params), do: traverse_change(term, params)

  defp traverse_change(existing_value, {key, params}) when is_map(params) and not is_struct(params) do
    traverse_change(existing_value, {key, Map.to_list(params)})
  end

  defp traverse_change([], _) do
    []
  end

  defp traverse_change([{_, _} | _] = keyword, {key, params}) do
    change =
      keyword
      |> Keyword.get(key)
      |> traverse_change(params)

    Keyword.put(keyword, key, change)
  end

  defp traverse_change([head | tail], {key, params}) do
    [
      traverse_change(head, {key, params}) |
      traverse_change(tail, {key, params})
    ]
  end

  defp traverse_change(map, {key, params}) when is_map(map) and not is_struct(map) do
    change =
      map
      |> Map.get(key)
      |> traverse_change(params)

    Map.put(map, key, change)
  end

  defp traverse_change(existing_value, {_key, []}) do
    existing_value
  end

  defp traverse_change(existing_value, {key, [head | todo]}) do
    existing_value
    |> traverse_change({key, head})
    |> traverse_change({key, todo})
  end

  defp traverse_change(existing_value, params) when is_map(params) do
    traverse_change(existing_value, Map.to_list(params))
  end

  defp traverse_change(existing_value, []) do
    existing_value
  end

  defp traverse_change(existing_value, [head | todo]) do
    existing_value
    |> traverse_change(head)
    |> traverse_change(todo)
  end

  defp traverse_change(existing_value, {key, {operation, replacement}}) do
    if compare?(existing_value, operation, key) do
      resolve(replacement, existing_value, key)
    else
      existing_value
    end
  end

  defp traverse_change(existing_value, {key, replacement}) do
    if compare?(existing_value, :===, key) do
      resolve(replacement, existing_value, key)
    else
      existing_value
    end
  end

  defp resolve(func, existing_value, pattern) when is_function(func, 2), do: func.(existing_value, pattern)
  defp resolve(func, existing_value, _pattern) when is_function(func, 1), do: func.(existing_value)
  defp resolve(func, _existing_value,  _pattern) when is_function(func), do: func.()
  defp resolve(replacement, _existing_value,  _pattern), do: replacement
end
