defmodule Mi.AST do
  @type t :: [tnode]

  @type tnode :: Lambda.t
               | List.t
               | Expression.t
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

  defmodule List do
    defstruct [:items]

    @type t :: %__MODULE__{ items: [AST.tnode] }
  end

  defmodule Expression do
    @enforce_keys [:operator, :arguments]
    defstruct [:operator, :arguments]

    @type t :: %__MODULE__{
      operator: atom,
      arguments: [AST.tnode]
    }
  end

  defmodule Identifier do
    @enforce_keys [:name]
    defstruct [:name]

    @type t :: %__MODULE__{ name: String.t }
  end

  defmodule Symbol do
    @enforce_keys [:name]
    defstruct [:name]

    @type t :: %__MODULE__{ name: String.t }
  end

  defmodule Number do
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{ value: String.t }
  end

  defmodule String do
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{ value: String.t }
  end
end
