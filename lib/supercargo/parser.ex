defmodule Supercargo.Parser do
  import Supercargo.Guards

  def parse(sources, structure) do
    uncategorized_variables = traverse_for_uncategorized_variables(structure)
    categories = traverse_for_categories(structure)

    [%Sources{names: sources, structure: structure}] ++
      categories ++ uncategorized_variables
  end

  defp traverse_for_uncategorized_variables(structure) do
    Enum.map(
      structure,
      fn
        {first_term, second_term} when is_uncategorized_variable(first_term, second_term) ->
          %UncategorizedVariable{fields: first_term, identifier: second_term}

        _ ->
          %{}
      end
    )
  end

  """
    Produces virtual AST
      [
        %Category.Group{
          name: :other_fields,
          entries:[
            %Category.Entry{
              fields: ["Field1", "Field2"],
              identifier: :identifier,
              type_constraint: :string,
              value_constraint: [a-zA-Z]
              },
            ...
          ]
        ...
      ]
  """

  defp traverse_for_categories(structure) do
    Enum.map(
      structure,
      fn
        {first_term, second_term} when is_category(first_term, second_term) ->
          entries = traverse_category_items(second_term, first_term)
          %Category.Group{entries: entries, name: first_term}

        _ ->
          %{}
      end
    )
  end

  """
    Produces virtual AST 
      [
        %Category.Entry{
          fields: ["Field1", "Field2"],
          identifier: :identifier,
          type_constraint: :string,
          value_constraint: [a-zA-Z]
        },
        ...
      ]
  """

  defp traverse_category_items(structure, category_name) do
    Enum.map(
      structure,
      fn
        {first_term, second_term} when are_fields_and_identifier(first_term, second_term) ->
          %Category.Entry{fields: first_term, identifier: second_term}

        {first_term, second_term = [identifier, type_constraint, value_constraint]}
        when are_fields_and_constraint_block(first_term, second_term) ->
          %Category.Entry{
            fields: first_term,
            identifier: identifier,
            type_constraint: type_constraint,
            value_constraint: value_constraint
          }

        _ ->
          %{}
      end
    )
  end

end
