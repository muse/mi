defmodule Mi.Codegen do
  alias Mi.{AST, Codegen}

  defstruct program: [], ast: []

  @type t :: %__MODULE__{
    program: String.t,
    ast: AST.t
  }

  @renamed_operators %{not: "!", and: "&&", or: "||", eq: "==="}

  @spec generate(AST.t) :: String.t
  def generate(ast), do: do_generate(%Codegen{ast: ast})

  @spec do_generate(Codegen.t) :: {:ok, String.t}
  defp do_generate(%Codegen{ast: [], program: program}) do
    {:ok, program |> Enum.reverse |> Enum.join}
  end
  defp do_generate(%Codegen{ast: [node | rest]} = codegen) do
    result = generate_top_level(node)
    do_generate(%{codegen | ast: rest, program: [result | codegen.program]})
  end

  @spec generate_top_level(AST.tnode | [AST.tnode]) :: String.t
  defp generate_top_level([]), do: ""
  defp generate_top_level([func | args]) do
    # A list in the AST means a function call
    # TODO: make AST type for function calls instead of using a list
    generate_func_call(func, args) <> ";"
  end
  defp generate_top_level(node) do
    result = generate_node(node)

    # Don't insert semicolon when generating statements
    if node.statement?,
      do: result,
      else: result <> ";"
  end

  @spec identifier(String.t) :: String.t
  defp identifier(string) do
    [first | rest] = String.replace(string, "/", ".") |> String.split("-")
    if rest !== [] do
      first <> (rest |> Enum.map(&String.capitalize/1) |> Enum.join)
    else
      first
    end
  end

  @spec generate_node(AST.tnode) :: String.t
  defp generate_node([]), do: ""
  defp generate_node(node) do
    case node do
      %AST.List{}       -> generate_list(node)
      %AST.Expression{} -> generate_expression(node)
      %AST.Lambda{}     -> generate_lambda(node)
      %AST.Define{}     -> generate_variable(node)
      %AST.Defun{}      -> generate_function(node)
      %AST.If{}         -> generate_if(node)
      %AST.Use{}        -> generate_use(node)
      %AST.Number{}     -> node.value
      %AST.String{}     -> ~s("#{node.value}")
      %AST.Symbol{}     -> ~s("#{node.name}")
      %AST.Identifier{} -> identifier(node.name)
      %AST.Bool{}       -> node.value
      %AST.Nil{}        -> "null"
      %AST.Object{}     -> generate_object(node)
      %AST.Return{}     -> generate_return(node)
      %AST.For{}        -> generate_for(node)
      [func | args]     -> generate_func_call(func, args)
    end
  end

  @spec generate_list(AST.List.t) :: String.t
  defp generate_list(%AST.List{items: items}) do
    items = Enum.map(items, &generate_node/1) |> Enum.join(", ")
    "[#{items}]"
  end

  @spec generate_expression(AST.Expression.t) :: String.t
  defp generate_expression(%AST.Expression{arguments: args, operator: operator}) do
    # We renamed some operators, i.e `and' instead of `&&'. This converts them
    # back to their JavaScript equivalent.
    operator = Map.get(@renamed_operators, operator, operator)

    args = Enum.map(args, &generate_node/1)

    case operator do
      :"//" ->
        [lhs, rhs] = args
        "Math.floor(#{lhs} / #{rhs})"
      :"**" ->
        [lhs, rhs] = args
        "Math.pow(#{lhs}, #{rhs})"
      :. ->
        # No parentheses and spaces around operator `.'
        expression = args |> Enum.join("#{operator}")
        "#{expression}"
      _ ->
        if length(args) > 1 do
          expression = args |> Enum.join(" #{operator} ")
          "(#{expression})"
        else
          # Unary operators
          [arg] = args
          "#{operator}(#{arg})"
        end
    end
  end

  @spec generate_lambda(AST.Lambda.t) :: String.t
  defp generate_lambda(%AST.Lambda{} = lambda) do
    name = if lambda.name, do: identifier(lambda.name), else: ""
    params = Enum.join(lambda.parameters, ", ")
    body = generate_body(lambda.body)

    if length(lambda.body) > 1 do
      "function #{name}(#{params}) {
      #{body}
      }"
    else
      "function #{name}(#{params}) { #{body} }"
    end
  end

  @spec generate_body([AST.tnode]) :: String.t
  defp generate_body(nodes) when is_list(nodes) do
    Enum.map(nodes, &generate_top_level/1)
  end
  defp generate_body(node) do
    generate_top_level(node)
  end

  @spec generate_variable(AST.Define.t) :: String.t
  defp generate_variable(%AST.Define{} = variable) do
    name = identifier(variable.name)
    value = generate_node(variable.value)
    expression =
      if variable.default?,
        do: "#{name} || #{value}",
        else: value

    "var #{name} = #{expression};"
  end

  @spec generate_function(AST.Defun.t) :: String.t
  defp generate_function(%AST.Defun{} = function) do
    name = identifier(function.name)
    params = Enum.join(function.parameters, ", ")
    body = generate_body(function.body)

    "function #{name}(#{params}) {
#{body}
}"
  end

  @spec generate_if(AST.If.t) :: String.t
  defp generate_if(%AST.If{} = if_stmt) do
    condition = generate_node(if_stmt.condition)
    true_body = generate_body(if_stmt.true_body)

    if if_stmt.false_body do
      false_body = generate_body(if_stmt.false_body)
      "if (#{condition}) {
      #{true_body}
      } else {
      #{false_body}
      }"
    else
      "if (#{condition}) {
      #{true_body}
      }"
    end
  end

  @spec generate_use(AST.Use.t) :: String.t
  defp generate_use(%AST.Use{} = use_stmt) do
    module_name = generate_node(use_stmt.module)
    "var #{use_stmt.name} = require(#{module_name});"
  end

  @spec generate_func_call(AST.tnode, [AST.tnode]) :: String.t
  defp generate_func_call(func, args) do
    name = generate_node(func)
    args = Enum.map(args, &generate_node/1) |> Enum.join(", ")
    "#{name}(#{args})"
  end

  @spec generate_object(AST.tnode) :: String.t
  defp generate_object(%AST.Object{} = node) do
    fields = Enum.map(node.value, fn field ->
      {key_node, value_node} = field
      key = generate_node(key_node)
      field = generate_node(value_node)
      "#{key}: #{field}"
    end)
    object = Enum.join(fields, ", ")
    "{#{object}}"
  end

  @spec generate_return(AST.tnode) :: String.t
  defp generate_return(%AST.Return{value: nil}) do
    "return;"
  end
  defp generate_return(%AST.Return{} = node) do
    expression = generate_node(node.value)
    "return #{expression};"
  end

  @spec generate_for(AST.tnode) :: String.t
  defp generate_for(%AST.For{} = node) do
    body = generate_body(node.body)
    "#{body}"
  end
end
