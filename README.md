## Introduction

Effective error handling reduces complexity and improves security. By minimizing variation in
error messages and avoiding the leakage of sensitive information, you can make your application
more predictable and secure. Consistent error messages also simplify the user experience and
reduce the need for extensive documentation.

This API standardizes error message formatting to maintain consistency and control over what
is exposed to users. It normalizes error messages in a predictable, flexible, and testable
manner.

This API represents error messages as a map with three fields:

  * `:code` - The HTTP code, represented as an atom.
  * `:message` - The error message, represented as a string.
  * `:details` - Additional details, either nil or a map.

Normalizing these fields ensures that only relevant and controlled error information is sent to
clients.

The API works by matching on terms given parameters that describe the comparison operation to
use and the value to compare the term to. If a match is found, the API replaces the term with a
predefined value or the value returned from a callback function.

Let's look at an example. Consider a function that returns error messages with various HTTP codes:

  * `:bad_request`
  * `:request_timeout`
  * `:service_unavailable`
  * `:internal_server_error`

Handling all these codes separately can complicate your API's user experience and documentation.
Instead, you can group similar errors into a broader category, such as `:internal_server_error`.
This approach reduces complexity and limits the information exposed to users, focusing on a single,
general error code.

The same normalization principles apply to the message and details fields. By defining parameters
and replacement values, you can ensure these fields are transformed consistently, enhancing both
security and clarity.

This API does not standardize your system's error codes. For that functionality check out [ErrorMessage](https://hexdocs.pm/error_message/ErrorMessage.html).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `error_message_shorts` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:error_message_shorts, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/error_message_shorts>.

