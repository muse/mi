defmodule Mi.Parser do
  @moduledoc """
  The parser will generate an abstract syntax tree representing the program's
  structure.
  """

  alias Mi.{Parser, Token}

  defstruct ast: [], tokens: []

  @spec parse([%Token{}]) :: %Parser{}
  def parse(%Parser{tokens: []} = parser), do: parser.ast
  def parse(%Parser{tokens: [head | tail]} = parser) do
    parse(%{parser | tokens: tail})
  end
  def parse(tokens), do: parse(%Parser{tokens: tokens})
end
