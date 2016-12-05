defmodule Mi.Parser do
  @moduledoc """
  The parser will generate an abstract syntax tree representing the program's
  structure.
  """

  alias Mi.{Parser, Lexer, Token, AST}

  defstruct ast: [], tokens: []

  @type t :: %__MODULE__{
    ast: AST.t,
    tokens: [Token.t]
  }

  @operators [:not, :and, :or, :eq, :delete, :typeof, :void, :new, :instanceof,
              :in, :from, :increment, :decrease, :intdivide, :power, :bshiftl,
              :ubshiftr, :bshiftr, :lteq, :gteq, :subtract, :add, :divide, :*,
              :modulo, :lt, :gt, :bnot, :bxor, :bor, :band]

  @statements [:use, :lambda]

  defmacro is_operator(type) do
    quote do: unquote(type) in @operators
  end

  defmacro is_statement(type) do
    quote do: unquote(type) in @statements
  end

  @spec parse(String.t) :: AST.t
  def parse(expr) do
    case Lexer.lex(expr) do
      {:ok, tokens} -> do_parse(%Parser{tokens: tokens})
      error         -> error
    end
  end

  @spec do_parse(Parser.t) :: {:ok, AST.t} | {:error, String.t}
  defp do_parse(%Parser{tokens: []} = parser) do
    {:ok, parser.ast}
  end
  defp do_parse(%Parser{tokens: [%Token{type: :oparen} | rest]} = parser) do
    {rest, node} = parse_list(%{parser | tokens: rest})
    do_parse(%{parser | tokens: rest, ast: [node | parser.ast]})
  end
  defp do_parse(%Parser{tokens: [token | _]}) do
    {:error, "unexpected token `#{token}', expecting `('"}
  end

  @spec parse_list(Parser.t) :: AST.t | AST.tnode
  defp parse_list(%Parser{tokens: [%Token{type: type} | rest]} = parser) when is_operator(type),
    do: parse_expression(%{parser | tokens: rest}, type)
  defp parse_list(%Parser{tokens: [%Token{type: type} | _]} = parser) when is_statement(type),
    do: parse_statement(parser)
  defp parse_list(%Parser{} = parser),
    do: parse_list(parser, [])

  @spec parse_list(Parser.t, [AST.tnode]) :: AST.t
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list) do
    {rest, Enum.reverse(list)}
  end
  defp parse_list(%Parser{} = parser, list) do
    {rest, node} = parse_atom(parser)
    parse_list(%{parser | tokens: rest}, [node | list])
  end

  @spec parse_atom(Parser.t) :: {[Token.t], AST.tnode | AST.t}
  defp parse_atom(%Parser{tokens: [%Token{type: :quote}, token | rest]} = parser) do
    # Quoted atom sometimes have a special case, otherwise it's just ignored
    case token.type do
      :oparen     -> parse_literal_list(%{parser | tokens: rest})
      :identifier -> {rest, %AST.Symbol{name: token.value}}
      :number     -> {rest, %AST.Symbol{name: token.value}}
      _           -> parse_atom(%{parser | tokens: [token | rest]})
    end
  end
  defp parse_atom(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest})
      :identifier -> {rest, %AST.Identifier{name: token.value}}
      :number     -> {rest, %AST.Number{value: token.value}}
      :string     -> {rest, %AST.String{value: token.value}}
      :use        -> parse_use(%{parser | tokens: rest})
      _           -> nil # TODO: error
    end
  end

  @spec parse_statement(Parser.t) :: AST.tnode
  defp parse_statement(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :use -> parse_use(%{parser | tokens: rest})
      _    -> nil # TODO: error
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

  @spec parse_expression(Parser.t, atom, [AST.tnode]) :: {[Token.t], AST.Expression.t}
  defp parse_expression(parser, operator, arguments \\ [])
  defp parse_expression(%Parser{tokens: [%Token{type: :cparen} | rest]}, operator, arguments) do
    {rest, %AST.Expression{operator: operator,
                           arguments: Enum.reverse(arguments)}}
  end
  defp parse_expression(%Parser{} = parser, operator, arguments) do
    {rest, node} = parse_atom(parser)
    parse_expression(%{parser | tokens: rest}, operator, [node | arguments])
  end

  @spec parse_use(Parser.t) :: {[Token.t], AST.Use.t}
  defp parse_use(%Parser{tokens: [%Token{type: :*},
                                  %Token{type: :string} = module,
                                  %Token{type: :string} = name,
                                  %Token{type: :cparen} | rest]}) do
    {rest, %AST.Use{module: module.value, name: name.value}}
  end
  defp parse_use(%Parser{tokens: [%Token{type: :string} = module,
                                  %Token{type: :cparen} | rest]}) do
    {rest, %AST.Use{module: module.value, name: module.value}}
  end
end
