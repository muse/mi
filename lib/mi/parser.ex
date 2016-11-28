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
  defp do_parse(%Parser{tokens: []} = parser) do
    {:ok, parser.ast}
  end
  defp do_parse(%Parser{tokens: [%Token{type: :oparen} | rest]} = parser) do
    {rest, list} = parse_list(%{parser | tokens: rest})
    do_parse(%{parser | tokens: rest, ast: [list | parser.ast]})
  end
  defp do_parse(%Parser{tokens: [token | _rest]}) do
    {:error, "unexpected token '#{token}'"}
  end

  @spec parse_list(Parser.t) :: AST.t
  defp parse_list(parser, list \\ [])
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list) do
    {rest, Enum.reverse(list)}
  end
  defp parse_list(%Parser{} = parser, list) do
    {rest, node} = parse_atom(parser)
    parse_list(%{parser | tokens: rest}, [node | list])
  end

  @spec parse_atom(Parser.t) :: {[Token.t], AST.tnode | AST.t}
  defp parse_atom(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest})
      :operator   -> {rest, %AST.Operator{value: List.to_atom([token.value])}}
      :identifier -> {rest, %AST.Identifier{value: token.value}}
      :number     -> {rest, %AST.Number{value: token.value}}
      :symbol     -> {rest, %AST.Symbol{value: token.value}}
      :string     -> {rest, %AST.String{value: token.value}}
    end
  end
end
