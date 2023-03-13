defprotocol Generator do
  @fallback_to_any true
  def run(token, sources)
end

defimpl Generator, for: Any do
  def run(token, sources) do
  end
end
