defmodule Mi.Codegen do
  alias Mi.{AST, Codegen}

  defstruct program: [], ast: []

  @type t :: %__MODULE__{
    program: String.t,
    ast: AST.t
  }

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
  defp generate_top_level([func | args]) do
    # A list in the AST means a function call
    generate_func_call(func, args) <> ";"
  end
  defp generate_top_level(node) do
    result = generate_node(node)

    # Don't insert semicolon when generating statements
    if node.statement?,
      do: result,
      else: result <> ";"
  end

  @spec generate_node(AST.tnode) :: String.t
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
      %AST.Identifier{} -> String.replace(node.name, "/", ".")
      %AST.Bool{}       -> node.value
      %AST.Nil{}        -> "null"
    end
  end

  @spec generate_list(AST.List.t, [String.t]) :: String.t
  defp generate_list(list, generated_items \\ [])
  defp generate_list(%AST.List{items: []}, generated_items) do
    items = generated_items |> Enum.reverse |> Enum.join(", ")
    "[#{items}]"
  end
  defp generate_list(%AST.List{items: [item | rest]} = list, generated_items) do
    result = generate_node(item)
    generate_list(%{list | items: rest}, [result | generated_items])
  end

  @spec generate_expression(AST.Expression.t, [String.t]) :: String.t
  defp generate_expression(expr, generated_items \\ [])
  defp generate_expression(%AST.Expression{arguments: [], operator: :.} = expr, generated_args) do
    # No parentheses and spaces around operator `.'
    expression = generated_args |> Enum.reverse |> Enum.join("#{expr.operator}")
    "#{expression}"
  end
  defp generate_expression(%AST.Expression{arguments: []} = expr, generated_args) do
    expression = generated_args |> Enum.reverse |> Enum.join(" #{expr.operator} ")
    "(#{expression})"
  end
  defp generate_expression(%AST.Expression{arguments: [arg | rest]} = expr, generated_args) do
    result = generate_node(arg)
    generate_expression(%{expr | arguments: rest}, [result | generated_args])
  end

  @spec generate_lambda(AST.Lambda.t) :: String.t
  defp generate_lambda(%AST.Lambda{} = lambda) do
    params = Enum.join(lambda.parameters, ", ")
    body = generate_body(lambda.body)

    if length(lambda.body) > 1 do
      "function #{lambda.name}(#{params}) {
      #{body}
      }"
    else
      "function #{lambda.name}(#{params}) { #{body} }"
    end
  end

  @spec generate_body([AST.tnode], [String.t]) :: String.t
  defp generate_body(nodes, generated_nodes \\ [])
  defp generate_body([], generated_nodes) do
    generated_nodes |> Enum.reverse
  end
  defp generate_body([node | rest], generated_nodes) do
    result = generate_top_level(node)
    generate_body(rest, [result | generated_nodes])
  end

  @spec generate_variable(AST.Define.t) :: String.t
  defp generate_variable(%AST.Define{} = variable) do
    value = generate_node(variable.value)
    expression =
      if variable.default?,
        do: "#{variable.name} || #{value}",
        else: value

    "var #{variable.name} = #{expression};"
  end

  @spec generate_function(AST.Defun.t) :: String.t
  defp generate_function(%AST.Defun{} = function) do
    params = Enum.join(function.parameters, ", ")
    body = generate_body(function.body)

    "function #{function.name}(#{params}) {
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
    "var #{use_stmt.name} = require(\"#{use_stmt.module}\");"
  end

  @spec generate_func_call(AST.tnode, [AST.tnode]) :: String.t
  defp generate_func_call(func, args) do
    name = generate_node(func)
    args = Enum.map(args, &generate_node/1) |> Enum.join(", ")
    "#{name}(#{args})"
  end
end
