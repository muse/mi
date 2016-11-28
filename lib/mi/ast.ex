defmodule Mi.AST do
  @moduledoc """
  """

  @type t :: [tnode]

  @type tnode :: Lambda.t
               | Operator.t
               | Identifier.t
               | Symbol.t
               | Number.t
               | String.t

  defmodule Lambda do
    defstruct [:args, :body]

    @type t :: %__MODULE__{
      args: [String.t],
      body: [AST.tnode]
    }
  end

  defmodule Operator do
    defstruct [:value]

    @type t :: %__MODULE__{ value: atom }
  end

  defmodule Identifier do
    defstruct [:value]

    @type t :: %__MODULE__{ value: charlist }
  end

  defmodule Symbol do
    defstruct [:value]

    @type t :: %__MODULE__{ value: charlist }
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
