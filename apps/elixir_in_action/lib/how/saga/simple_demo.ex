defmodule How.Saga.SimpleDemo do
  alias How.Saga.DummyApi

  require Logger

  def run() do
    simple_workflow(%{sub_id: "123456", rg_name: "rg01", aks: "aks01"})
  end

  def simple_workflow(attrs) do
    # If we don't supply compensation function, then it has effect to abort the workflow and compensate previous actions.
    # No matter what, side effects must not be created from compensating transaction.
    # See: https://hexdocs.pm/sage/Sage.html#types
    # See: https://medium.com/nebo-15/introducing-sage-a-sagas-pattern-implementation-in-elixir-3ad499f236f6
    # Other references:
    # https://mcode.it/blog/2021-02-18-fsharp_outbox/
    # https://github.com/Nebo15/sage
    # https://hexdocs.pm/sage/0.6.3/readme.html
    # https://medium.com/nebo-15/introducing-sage-a-sagas-pattern-implementation-in-elixir-3ad499f236f6
    Sage.new()
    |> Sage.run(
      :rg,
      fn _effect_so_far, attrs ->
        DummyApi.create_rg(attrs)
      end,
      fn _effect_to_compensate, _effect_so_far, attrs ->
        DummyApi.create_rg_breaker(attrs)
      end
    )
    |> Sage.run(
      :aks,
      fn _effect_so_far, attrs ->
        DummyApi.create_ask(attrs)
      end,
      fn _effect_to_compensate, _effect_so_far, attrs ->
        DummyApi.create_ask_breaker(attrs)
      end
    )
    |> Sage.run(
      :pod,
      fn _effect_so_far, attrs -> DummyApi.create_pods(attrs) end,
      fn _effect_to_compensate, _effect_so_far, attrs ->
        DummyApi.create_pods_breaker(attrs)
      end
    )
    |> Sage.with_compensation_error_handler(DummyApi)
    |> Sage.finally(fn result, attrs ->
      Logger.info("===Summary")
      Logger.info("In finally stage, we could do clean up or summary")

      case result do
        :ok ->
          Logger.info("===OK, do summary for complete successful report")

        :error ->
          Logger.warning("===Error, do summary for what error happended")
          Logger.info(attrs)
      end
    end)
    |> Sage.execute(attrs)
  end
end
