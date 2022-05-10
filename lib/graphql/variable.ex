defmodule GraphQL.Variable do
  @moduledoc """
  A struct to represent GraphQL variables
  """
  defstruct name: nil, type: nil, default_value: nil

  @typedoc """
  A GraphQL generic name
  """
  @type name() :: String.t() | atom()

  @typedoc """
  A struct that represents the definition of a GraphQL variable.

  A variable definition exists within a query or mutation, and then can be
  referenced by the arguments of fields.
  """
  @type t :: %__MODULE__{
          name: name(),
          type: name(),
          default_value: any()
        }

  @doc """
  Check if two variables represent the same variable
  """
  @spec same?(t(), t()) :: boolean()
  def same?(%__MODULE__{} = a, %__MODULE__{} = b) do
    name_a = term_as_string(a.name)
    name_b = term_as_string(b.name)

    name_a == name_b
  end

  defp term_as_string(term) when is_atom(term), do: Atom.to_string(term)
  defp term_as_string(term) when is_binary(term), do: term
end
