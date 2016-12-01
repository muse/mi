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

  defmacro is_operator(token) do
    quote do
      unquote(token.type) in [:not, :and, :or, :eq, :delete, :typeof, :void,
                              :new, :instanceof, :in, :from, :increment,
                              :decrease, :intdivide, :power, :bshiftl,
                              :ubshiftr, :bshiftr, :lteq, :gteq, :subtract,
                              :add, :divide, :*, :modulo, :lt, :gt, :bnot,
                              :bxor, :bor, :band]
    end
  end

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
    {:error, "unexpected token `#{token}'"}
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
  defp parse_atom(%Parser{tokens: [token | rest] = tokens}) when is_operator(token) do
    parse_expression(token, rest)
  end
  defp parse_atom(%Parser{tokens: [%Token{type: :quote}, token | rest]} = parser) do
    # Quoted atom sometimes have a special case, otherwise it's just ignored
    case token.type do
      :oparen     -> parse_literal_list(%{parser | tokens: rest})
      :identifier -> {rest, %AST.Symbol{name: token.value}}
      _           -> parse_atom(%{parser | tokens: rest}) # No special quote case
    end
  end
  defp parse_atom(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest})
      :identifier -> {rest, %AST.Identifier{name: token.value}}
      :number     -> {rest, %AST.Number{value: token.value}}
      :string     -> {rest, %AST.String{value: token.value}}
      _           -> nil
    end
  end

  @spec parse_literal_list(Parser.t) :: {[Token.t], AST.List.t}
  defp parse_literal_list(parser, list \\ [])
  defp parse_literal_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list) do
    {rest, %AST.List{items: Enum.reverse(list)}}
  end
  defp parse_literal_list(%Parser{} = parser, list) do
    {rest, node} = parse_atom(parser)
    parse_literal_list(%{parser | tokens: rest}, [node | list])
  end
end
