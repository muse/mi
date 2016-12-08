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

  @type tree_result :: {[Token.t], AST.t } | {:error, String.t}
  @type node_result :: {[Token.t], AST.tnode} | {:error, String.t}

  @unary_operators [:not, :delete, :typeof, :void, :new, :increment, :decrease,
                    :bnot]

  @operators [:and, :or, :eq, :instanceof, :in, :intdivide, :power, :bshiftl,
              :ubshiftr, :bshiftr, :lteq, :gteq, :subtract, :add, :divide, :*,
              :modulo, :lt, :gt, :bxor, :bor, :band, :dot | @unary_operators]

  @statements [:use, :lambda]

  defmacro is_unary_operator(type) do
    quote do: unquote(type) in @unary_operators
  end

  defmacro is_operator(type) do
    quote do: unquote(type) in @operators
  end

  defmacro is_statement(type) do
    quote do: unquote(type) in @statements
  end

  @spec parse(String.t) :: {:ok, AST.t} | {:error, String.t}
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
    case parse_list(%{parser | tokens: rest}) do
      {:error, reason} -> {:error, reason}
      {rest, node} ->
        do_parse(%{parser | tokens: rest, ast: [node | parser.ast]})
    end
  end
  defp do_parse(%Parser{tokens: [token | _]}) do
    {:error, error(token, "unexpected token `#{token}', expecting `('")}
  end

  @spec parse_list(Parser.t) :: tree_result
  defp parse_list(%Parser{tokens: [%Token{type: type} = token | rest]} = parser) when is_operator(type),
    do: parse_expression(%{parser | tokens: rest}, token)
  defp parse_list(%Parser{tokens: [%Token{type: type} | _]} = parser) when is_statement(type),
    do: parse_statement(parser)
  defp parse_list(%Parser{} = parser),
    do: parse_list(parser, [])

  @spec parse_list(Parser.t, [AST.tnode], boolean) :: tree_result
  defp parse_list(parser, list, literal \\ false)
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list, true) do
    {rest, %AST.List{items: Enum.reverse(list)}}
  end
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list, false) do
    {rest, Enum.reverse(list)}
  end
  defp parse_list(%Parser{} = parser, list, literal) do
    case parse_atom(parser) do
      {:error, message} -> {:error, message}
      {rest, node} ->
        parse_list(%{parser | tokens: rest}, [node | list], literal)
    end
  end

  @spec parse_atom(Parser.t) :: tree_result | node_result
  defp parse_atom(%Parser{tokens: [%Token{type: :quote}, token | rest]} = parser) do
    # Quoted atom sometimes have a special case, otherwise it's just ignored
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest}, [], true)
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
      _           -> {:error, error(token, "unexpected token #{token}")}
    end
  end

  @spec parse_statement(Parser.t) :: node_result
  defp parse_statement(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :use -> parse_use(%{parser | tokens: rest})
      _    -> {:error, error(token, "unexpected token #{token}")}
    end
  end

  @spec parse_expression(Parser.t, atom, [AST.tnode]) :: node_result
  defp parse_expression(parser, operator, arguments \\ [])
  defp parse_expression(%Parser{tokens: [%Token{type: :cparen} | rest]}, operator, arguments) do
    cond do
      is_unary_operator(operator) and length(arguments) > 1 ->
        {:error, "too many arguments for `#{operator}'"}
      not is_unary_operator(operator) and length(arguments) < 2 ->
        {:error, "not enough arguments for `#{operator}'"}
      :otherwise ->
        {rest, %AST.Expression{operator: operator.type,
                               arguments: Enum.reverse(arguments)}}
    end
  end
  defp parse_expression(%Parser{} = parser, operator, arguments) do
    {rest, node} = parse_atom(parser)
    parse_expression(%{parser | tokens: rest}, operator, [node | arguments])
  end

  @spec parse_use(Parser.t) :: node_result
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
  defp parse_use(%Parser{tokens: tokens}) do
    IO.inspect tokens
  end

  @spec error(Token.t, String.t) :: String.t
  defp error(token, message) do
    "#{token.line}:#{token.pos}: #{message}"
  end
end
