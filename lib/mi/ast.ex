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
               | Define.t
               | Use.t
               | If.t
               | Ternary.t
               | Defun.t
               | Object.t
               | Return.t
               | Condition.t
               | For.t
               | While.t
               | Case.t
               | Throw.t
               | Try.t

  defmodule List do
    defstruct [:items, statement?: false]

    @type t :: %__MODULE__{ items: [AST.tnode] }
  end

  defmodule Expression do
    @enforce_keys [:operator, :arguments]
    defstruct [:operator, :arguments, statement?: false]

    @type t :: %__MODULE__{
      operator: atom,
      arguments: [AST.tnode]
    }
  end

  defmodule Identifier do
    @enforce_keys [:name]
    defstruct [:name, statement?: false]

    @type t :: %__MODULE__{ name: String.t }
  end

  defmodule Symbol do
    @enforce_keys [:name]
    defstruct [:name, statement?: false]

    @type t :: %__MODULE__{ name: String.t }
  end

  defmodule Number do
    @enforce_keys [:value]
    defstruct [:value, statement?: false]

    @type t :: %__MODULE__{ value: String.t }
  end

  defmodule String do
    @enforce_keys [:value]
    defstruct [:value, statement?: false]

    @type t :: %__MODULE__{ value: String.t }
  end

  defmodule Bool do
    @enforce_keys [:value]
    defstruct [:value, statement?: false]

    @type t :: %__MODULE__{ value: String.t }
  end

  defmodule Nil do
    defstruct [statement?: false]

    @type t :: %__MODULE__{}
  end

  defmodule Lambda do
    @enforce_keys [:parameters, :body, :lexical_this?]
    defstruct [:name, :parameters, :body, :lexical_this?, statement?: false]

    @type t :: %__MODULE__{
      name: String.t,
      parameters: [String.t],
      body: [AST.tnode],
      lexical_this?: boolean
    }
  end

  defmodule Define do
    @enforce_keys [:name, :default?]
    defstruct [:name, :value, :default?, statement?: true]

    @type t :: %__MODULE__{
      name: String.t,
      value: AST.tnode,
      default?: boolean
    }
  end

  defmodule Defines do
    @enforce_keys [:values]
    defstruct [:values, statement?: true]

    @type t :: %__MODULE__{
      values: [AST.Define.t]
    }
  end

  defmodule Use do
    defstruct [:module, :name, statement?: true]

    @type t :: %__MODULE__{
      module: String.t,
      name: AST.tnode
    }
  end

  defmodule If do
    @enforce_keys [:condition, :true_body]
    defstruct [:condition, :true_body, :false_body, statement?: true]

    @type t :: %__MODULE__{
      condition: AST.tnode,
      true_body: [AST.tnode],
      false_body: [AST.tnode]
    }
  end

  defmodule Ternary do
    @enforce_keys [:condition, :true_body, :false_body]
    defstruct [:condition, :true_body, :false_body, statement?: false]

    @type t :: %__MODULE__{
      condition: AST.tnode,
      true_body: [AST.tnode],
      false_body: [AST.tnode]
    }
  end

  defmodule Defun do
    @enforce_keys [:name, :parameters, :body]
    defstruct [:name, :parameters, :body, statement?: true]

    @type t :: %__MODULE__{
      name: String.t,
      parameters: [String.t],
      body: [AST.tnode]
    }
  end

  defmodule Object do
    @enforce_keys [:value]
    defstruct [:value, statement?: false]

    @type t :: %__MODULE__{ value: [{AST.tnode, AST.tnode}] }
  end

  defmodule Return do
    defstruct [:value, statement?: true]

    @type t :: %__MODULE__{ value: AST.tnode }
  end

  defmodule Condition do
    @enforce_keys [:conditions]
    defstruct [:conditions, statement?: true]

    @type t :: %__MODULE__{ conditions: [{AST.tnode, AST.tnode}] }
  end

  defmodule For do
    defstruct [:initialization, :condition, :final_expression, :body,
               statement?: true]

    @type t :: %__MODULE__{
      initialization: AST.tnode,
      condition: AST.tnode,
      final_expression: AST.tnode,
      body: [AST.tnode]
    }
  end

  defmodule While do
    @enforce_keys [:condition]
    defstruct [:condition, :body, statement?: true]

    @type t :: %__MODULE__{
      condition: AST.tnode,
      body: [AST.tnode]
    }
  end

  defmodule Case do
    @enforce_keys [:match]
    defstruct [:match, :cases, statement?: true]

    @type t :: %__MODULE__{
      match: AST.tnode,
      cases: [AST.tnode]
    }
  end

  defmodule Throw do
    @enforce_keys [:expression]
    defstruct [:expression, statement?: true]

    @type t :: %__MODULE__{ expression: AST.tnode }
  end

  defmodule Try do
    @enforce_keys [:catch_expression]
    defstruct [:body, :catch_expression, :catch_body, :finally_body, statement?: true]

    @type t :: %__MODULE__{
      body: [AST.tnode],
      catch_expression: AST.tnode,
      catch_body: [AST.tnode],
      finally_body: [AST.tnode]
    }
  end
end
