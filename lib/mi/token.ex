defmodule Mi.Token do
  @moduledoc """
  A token is a categorization of text to be used by the parser.
  """

  alias Mi.Token

  @enforce_keys [:value, :type, :line, :pos]
  defstruct [:value, :type, :line, :pos]

  @type t :: %__MODULE__{
    value: charlist,
    type: type,
    line: pos_integer,
    pos: pos_integer
  }

  @type type :: atom

  defimpl String.Chars, for: Token do
    def to_string(token), do: "#{[token.value]}"
  end

  defmacro is_whitespace(c) do
    quote do: unquote(c) in [?\t, ?\s, ?\r]
  end

  defmacro is_numeric_literal(c) do
    quote do: unquote(c) in ?0..?9 or unquote(c) === ?.
  end

  defmacro is_identifier_literal(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or
      unquote(c) in ?0..?9 or unquote(c) in [?-, ?/, ?$]
  end

  defmacro is_start_of_identifier(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or unquote(c) === ?$
  end

  @keywords [
    'lambda',
    'define',
    'use',
    'loop',  # for, while
    'cond',  # if
    'case',
    'try',
    'catch',
    'throw',
    'true',
    'false',
    'nil',

    # Operators
    'not', 'and', 'or', 'eq', 'delete', 'typeof', 'void', 'new', 'instanceof',
    'in', 'from'
  ]

  @spec new(%{pos: pos_integer, line: pos_integer}, any, type) :: Token.t
  def new(%{pos: pos, line: line}, value, type) do
    %Token{
      value: to_string([value]),
      type: type,
      pos: pos,
      line: line
    }
  end

  @spec keyword?(charlist) :: boolean
  def keyword?(value), do: value in @keywords
end
