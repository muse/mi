defmodule Mi.AST do
  @moduledoc """
  """

  defmodule Lambda do
    defstruct [:args, :body]
  end

  defmodule Expression do
    defstruct [:operator, :lhs, :rhs]
  end
end
