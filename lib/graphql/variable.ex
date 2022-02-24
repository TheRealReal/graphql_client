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
end
