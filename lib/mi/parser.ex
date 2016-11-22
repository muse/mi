defmodule Mi.Parser do
  @moduledoc """
  The parser will generate an abstract syntax tree representing the program's
  structure.
  """

  alias Mi.{Parser, Token, AST}

  defstruct ast: [], tokens: []

  @type t :: %__MODULE__{
    ast: AST.t,
    tokens: [Token.t]
  }

  @spec parse([Token.t]) :: AST.t
  def parse(tokens), do: do_parse(%Parser{tokens: tokens})

  @spec do_parse(Parser.t) :: AST.t
  def do_parse(%Parser{tokens: []} = parser), do: parser.ast
  def do_parse(%Parser{tokens: [_head | tail]} = parser) do
    do_parse(%{parser | tokens: tail})
  end
end
