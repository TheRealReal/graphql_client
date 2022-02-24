defmodule GraphQL.Response do
  @moduledoc """
  Functions to handle GraphQL responses
  """
  @enforce_keys [:success?]
  defstruct [:data, :errors, :success?]

  @typedoc """
  A struct that contains the GraphQL response data.
  """
  @type t :: %__MODULE__{
          data: any(),
          errors: any(),
          success?: true | false | :partial
        }

  @doc """
  Creates a succes response with the given data

  ## Examples

      iex> success(%{field: "value"})
      %GraphQL.Response{success?: true, data: %{field: "value"}}
  """
  @spec success(map) :: t()
  def success(data) do
    %__MODULE__{success?: true, data: data, errors: nil}
  end

  @doc """
  Creates a new failure response with  the given errors

  ## Examples

      iex> failure([%{message: "some error", locations: [%{line: 2, column: 5}]}])
      %GraphQL.Response{success?: false, errors: [%{message: "some error", locations: [%{line: 2, column: 5}]}]}
  """
  @spec failure(map) :: t()
  def failure(errors) do
    %__MODULE__{success?: false, data: nil, errors: errors}
  end

  @doc """
  Create a new partial success response with the given data and errors

  ## Examples

      iex> data = %{field: "value"}
      %{field: "value"}
      iex> errors = [%{message: "some error", locations: [%{line: 2, column: 5}]}]
      [%{message: "some error", locations: [%{line: 2, column: 5}]}]
      iex> partial_success(data, errors)
      %GraphQL.Response{success?: :partial, data: %{field: "value"}, errors: [%{message: "some error", locations: [%{line: 2, column: 5}]}]}
  """
  @spec partial_success(map(), list()) :: t()
  def partial_success(data, errors) do
    %__MODULE__{success?: :partial, data: data, errors: errors}
  end
end
