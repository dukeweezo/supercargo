defmodule Supercargo.Parser.Validator do
  import Supercargo.Guards

  def validate!(sources, structure) do
    check_source(sources)
    check_field_or_category(structure)
  end

  defp check_source(sources) do
    Enum.each(
      sources,
      fn
        source when is_invalid_source(source) ->
          raise Supercargo.ArgumentError,
                "@ `#{source}`. Source must be in the format of [:atom, ...]."

        _ ->
          :ok
      end
    )
  end

  defp check_field_or_category(structure) do
    Enum.each(
      structure,
      fn
        {name, _} when is_invalid_first_term(name) ->
          raise Supercargo.ArgumentError,
                "@ `#{name}`. Field or category name must be in the format of :string or :atom."

        {name, second_term} when is_invalid_second_term(second_term) ->
          raise Supercargo.ArgumentError,
                "@ `#{name}`. The second term must be in the format of :map or :atom."

        kv = {name, second_term} when is_category(name, second_term) ->
          Enum.each(
            second_term,
            fn
              {field_list, _} when is_invalid_first_subterm(field_list) ->
                raise Supercargo.ArgumentError,
                      "@ `#{field_list}` for `#{name}`. The field list must be in the format of :list of one or more :string."

              {_, second_subterm} when is_invalid_second_subterm(second_subterm) ->
                raise Supercargo.ArgumentError,
                      "@ `#{second_subterm}` for `#{name}`. The second subterm must be in the format of :list or :atom."

              {_, second_subterm = [second_subterm_name, type_constraint, value_constraint]}
              when is_valid_second_subterm_with_constraint(second_subterm) ->
                cond do
                  is_invalid_second_subterm_name(second_subterm_name) ->
                    raise Supercargo.ArgumentError,
                          "@ `#{second_subterm_name}` for `#{name}`. The second subterm name must be in the format of :atom."

                  is_invalid_type_constraint(type_constraint) ->
                    raise Supercargo.ArgumentError,
                          "@ `#{type_constraint}` for `#{name}`. The type constraint must be a valid Ecto type."

                  is_invalid_regex_constraint(value_constraint) ->
                    raise Supercargo.ArgumentError,
                          "@ `#{value_constraint}` for `#{name}`. The type constraint must be a valid regular expression."

                  true ->
                    :ok
                end

              _ ->
                :ok
            end
          )

        _ ->
          :ok
      end
    )
  end
end
