defmodule Mi.AST do
  @moduledoc """
  """

  @type t :: [tnode]

  @type tnode :: Lambda.t
               | Expression.t
               | Number.t
               | String.t

  defmodule Lambda do
    defstruct [:args, :body]

    @type t :: %__MODULE__{
      args: [String.t],
      body: [AST.tnode]
    }
  end

  defmodule Expression do
    defstruct [:operator, :lhs, :rhs]

    @type t :: %__MODULE__{
      operator: atom,
      lhs: AST.tnode,
      rhs: AST.tnode
    }
  end

  defmodule Number do
    defstruct [:value]

    @type t :: %__MODULE__{ value: charlist }
  end

  defmodule String do
    defstruct [:value]

    @type t :: %__MODULE__{ value: charlist }
  end
end
