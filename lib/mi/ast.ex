defmodule Mi.AST do
  @type t :: [tnode]

  @type tnode :: List.t
               | Expression.t
               | Identifier.t
               | Symbol.t
               | Number.t
               | String.t
               | Bool.t
               | Nil.t
               | Lambda.t
               | Variable.t
               | Use.t
               | If.t
               | Function.t

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

  defmodule Bool do
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{ value: String.t }
  end

  defmodule Nil do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Lambda do
    @enforce_keys [:args, :body, :lexical_this?]
    defstruct [:name, :args, :body, :lexical_this?]

    @type t :: %__MODULE__{
      name: String.t,
      args: [String.t],
      body: [AST.tnode],
      lexical_this?: boolean
    }
  end

  defmodule Variable do
    @enforce_keys [:name, :default?]
    defstruct [:name, :value, :default?]

    @type t :: %__MODULE__{
      name: String.t,
      value: String.t,
      default?: boolean
    }
  end

  defmodule Use do
    defstruct [:module, :name]

    @type t :: %__MODULE__{
      module: String.t,
      name: String.t
    }
  end

  defmodule If do
    @enforce_keys [:condition, :true_body]
    defstruct [:condition, :true_body, :false_body]

    @type t :: %__MODULE__{
      condition: AST.tnode,
      true_body: [AST.tnode],
      false_body: [AST.tnode]
    }
  end

  defmodule Function do
    @enforce_keys [:name, :args, :body]
    defstruct [:name, :args, :body]

    @type t :: %__MODULE__{
      name: String.t,
      args: [String.t],
      body: [AST.tnode]
    }
  end
end
