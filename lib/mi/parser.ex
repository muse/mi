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
                    :bnot, :minus]

  @multi_arity_operators [:and, :or, :eq, :instanceof, :in, :intdivide, :power,
                          :bshiftl, :ubshiftr, :bshiftr, :lteq, :gteq, :minus,
                          :plus, :divide, :*, :modulo, :lt, :gt, :bxor, :bor,
                          :band, :dot, :ternary]

  @operators @unary_operators ++ @multi_arity_operators

  @statements [:lambda, :define, :use]

  defmacrop is_unary(operator) do
    quote do: unquote(operator) in @unary_operators
  end

  defmacrop is_multi_arity(operator) do
    quote do: unquote(operator) in @multi_arity_operators
  end

  defmacrop is_operator(type) do
    quote do: unquote(type) in @operators
  end

  defmacrop is_statement(type) do
    quote do: unquote(type) in @statements
  end

  @spec error(Token.t, String.t) :: {:error, String.t}
  defp error(token, message) do
    {:error, "#{token.line}:#{token.pos}: #{message}"}
  end

  @spec expect([Token.t], atom | String.t) :: {:ok, Token.t, [Token.t]} | {:error, String.t}
  defp expect([%Token{value: value} = token | rest], expected)
  when is_binary(expected) and value === expected do
    {:ok, rest, token}
  end
  defp expect([%Token{type: type} = token | rest], expected)
  when is_atom(expected) and type === expected do
    {:ok, rest, token}
  end
  defp expect([token | _], expected) do
    error(token, "unexpected token '#{token}`, expecting `#{expected}'")
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
    {:ok, Enum.reverse(parser.ast)}
  end
  defp do_parse(%Parser{tokens: [%Token{type: :oparen} | rest]} = parser) do
    case parse_list(%{parser | tokens: rest}) do
      {:error, reason} -> {:error, reason}
      {:ok, rest, node} ->
        do_parse(%{parser | tokens: rest, ast: [node | parser.ast]})
    end
  end
  defp do_parse(%Parser{tokens: [%Token{type: :cparen} = token | _]}) do
    error(token, "mismatched `)'")
  end
  defp do_parse(%Parser{tokens: [token | _]}) do
    error(token, "unexpected token `#{token}', expecting `('")
  end

  @spec parse_list(Parser.t) :: tree_result
  defp parse_list(%Parser{tokens: [%Token{type: type} = token | rest]} = parser)
  when is_operator(type),
    do: parse_expression(%{parser | tokens: rest}, token)
  defp parse_list(%Parser{tokens: [%Token{type: type} | _]} = parser)
  when is_statement(type),
    do: parse_statement(parser)
  defp parse_list(%Parser{} = parser),
    do: parse_list(parser, [])

  @spec parse_list(Parser.t, [AST.tnode], boolean) :: tree_result
  defp parse_list(parser, list, literal \\ false)
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list, true) do
    {:ok, rest, %AST.List{items: Enum.reverse(list)}}
  end
  defp parse_list(%Parser{tokens: [%Token{type: :cparen} | rest]}, list, false) do
    {:ok, rest, list |> Enum.reverse |> List.flatten}
  end
  defp parse_list(%Parser{} = parser, list, literal) do
    case parse_atom(parser) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} ->
        parse_list(%{parser | tokens: rest}, [node | list], literal)
    end
  end

  @spec parse_atom(Parser.t) :: tree_result | node_result
  defp parse_atom(%Parser{tokens: [%Token{type: :quote}, token | rest]} = parser) do
    # Quoted atom sometimes have a special case, otherwise it's just ignored
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest}, [], true)
      :identifier -> {:ok, rest, %AST.Symbol{name: token.value}}
      :number     -> {:ok, rest, %AST.Symbol{name: token.value}}
      _           ->
        # TODO: warn about unnecessary quote
        parse_atom(%{parser | tokens: [token | rest]})
    end
  end
  defp parse_atom(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :oparen     -> parse_list(%{parser | tokens: rest})
      :identifier -> {:ok, rest, %AST.Identifier{name: token.value}}
      :number     -> {:ok, rest, %AST.Number{value: token.value}}
      :string     -> {:ok, rest, %AST.String{value: token.value}}
      :true       -> {:ok, rest, %AST.Bool{value: "true"}}
      :false      -> {:ok, rest, %AST.Bool{value: "false"}}
      :nil        -> {:ok, rest, %AST.Nil{}}
      _           -> error(token, "unexpected token `#{token}'")
    end
  end

  @spec parse_statement(Parser.t) :: node_result
  defp parse_statement(%Parser{tokens: [token | rest]} = parser) do
    case token.type do
      :lambda -> parse_lambda(%{parser | tokens: rest})
      :define -> parse_define(%{parser | tokens: rest})
      :use    -> parse_use(%{parser | tokens: rest})
      _       -> error(token, "unexpected token `#{token}'")
    end
  end

  @spec parse_expression(Parser.t, atom, [AST.tnode]) :: node_result
  defp parse_expression(parser, operator, arguments \\ [])
  defp parse_expression(%Parser{tokens: [%Token{type: :cparen} | rest]}, operator, arguments) do
    cond do
      length(arguments) === 0 ->
        error(operator, "missing argument(s) for `#{operator}'")
      is_unary(operator.type) and is_multi_arity(operator.type) ->
        # Operators that can have 1 or more arguments like `-`
        {:ok, rest, %AST.Expression{operator: operator.type,
                                    arguments: Enum.reverse(arguments)}}
      is_unary(operator.type) and length(arguments) > 1 ->
        error(operator, "too many arguments for `#{operator}'")
      is_multi_arity(operator.type) and length(arguments) < 2 ->
        error(operator, "not enough arguments for `#{operator}'")
      :otherwise ->
        {:ok, rest, %AST.Expression{operator: operator.type,
                                    arguments: Enum.reverse(arguments)}}
    end
  end
  defp parse_expression(%Parser{} = parser, operator, arguments) do
    case parse_atom(parser) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} ->
        parse_expression(%{parser | tokens: rest}, operator, [node | arguments])
    end
  end

  # An argument list is a list of identifiers used in lambda and function
  # definitions.
  @spec parse_arg_list([Token.t]) :: [AST.Identifier.t]
  defp parse_arg_list([%Token{type: :oparen} | rest]) do
    parse_arg_list(rest, [])
  end
  defp parse_arg_list([token | _]) do
    error(token, "expecting argument list, got `#{token}'")
  end
  @spec parse_arg_list([Token.t], [AST.Identifier.t]) :: [AST.Identifier.t]
  defp parse_arg_list([%Token{type: :cparen} | rest], list) do
    {:ok, rest, Enum.reverse(list)}
  end
  defp parse_arg_list([%Token{type: :identifier} = token | rest], list) do
    parse_arg_list(rest, [%AST.Identifier{name: token.value} | list])
  end
  defp parse_arg_list([token | _], _) do
    error(token, "unexpected token `#{token}' in argument list")
  end

  @spec parse_lambda(Parser.t) :: node_result
  defp parse_lambda(%Parser{tokens: [%Token{type: :*} | rest]} = parser) do
    with {:ok, rest, name} <- expect(rest, :identifier),
         {:ok, rest, args} <- parse_arg_list(rest),
         {:ok, rest, body} <- parse_atom(%{parser | tokens: rest}),
         {:ok, rest, _} <- expect(rest, ")"),
      do: {:ok, rest, %AST.Lambda{name: name.value, args: args, body: body}}
  end
  defp parse_lambda(%Parser{} = parser) do
    with {:ok, rest, args} <- parse_arg_list(parser.tokens),
         {:ok, rest, body} <- parse_atom(%{parser | tokens: rest}),
         {:ok, rest, _} <- expect(rest, ")"),
      do: {:ok, rest, %AST.Lambda{args: args, body: body}}
  end

  @spec parse_define(Parser.t) :: node_result
  defp parse_define(%Parser{tokens: [%Token{type: :*} | rest]} = parser) do
    parse_define(%{parser | tokens: rest}, true)
  end
  defp parse_define(%Parser{} = parser, is_default \\ false) do
    with {:ok, rest, name}  <- expect(parser.tokens, :identifier),
         {:ok, rest, value} <- parse_atom(%{parser | tokens: rest}),
         {:ok, rest, _}     <- expect(rest, ")"),
      do: {:ok, rest, %AST.Define{name: name.value, value: value, is_default: is_default}}
  end

  @spec parse_use(Parser.t) :: node_result
  defp parse_use(%Parser{tokens: [%Token{type: :*} | rest]} = parser) do
    # TODO: improve error messages here. currently throws errors about
    #       unexpected )
    with {:ok, rest, module} <- expect(rest, :string),
         {:ok, rest, %AST.Symbol{name: name}} <- parse_atom(%{parser | tokens: rest}),
         {:ok, rest, _} <- expect(rest, ")"),
      do: {:ok, rest, %AST.Use{module: module.value, name: name}}
  end
  defp parse_use(%Parser{} = parser) do
    with {:ok, rest, module} <- expect(parser.tokens, :string),
         {:ok, rest, _}      <- expect(rest, ")"),
      do: {:ok, rest, %AST.Use{module: module.value, name: module.value}}
  end
end
