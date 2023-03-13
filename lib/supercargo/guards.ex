defmodule Supercargo.Guards do
  defguard is_invalid_source(value) when not is_atom(value)
  defguard is_invalid_first_term(value) when not is_bitstring(value) and not is_atom(value)
  defguard is_invalid_second_term(value) when not is_map(value) and not is_atom(value)
  defguard is_invalid_first_subterm(value) when not is_list(value)
  defguard is_invalid_second_subterm(value) when not is_atom(value) and not is_list(value)
  defguard is_valid_second_subterm_with_constraint(value) when is_list(value)
  defguard is_invalid_second_subterm_name(value) when not is_atom(value)
  @types [:integer, :float, :boolean, :string, :binary, :uuid, :decimal, :datetime, :date, :time]
  defguard is_invalid_type_constraint(value) when value not in @types
  defguard is_invalid_regex_constraint(value) when not is_struct(value)

  defguard is_category(category_name, structure) when is_atom(category_name) and is_map(structure)

  defguard is_uncategorized_variable(fields, identifier)
           when is_bitstring(fields) and is_atom(identifier)

  defguard are_fields_and_identifier(fields, identifier)
           when is_list(fields) and is_atom(identifier)

  defguard are_fields_and_constraint_block(fields, constraint_block)
           when is_list(fields) and is_list(constraint_block)
end
