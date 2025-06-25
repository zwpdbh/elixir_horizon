defmodule How.Snippets.SumType do
  @moduledoc """
  Show How sum type could be defined and used in elixir
  Ref: https://blog.appsignal.com/2022/05/31/algebraic-data-types-in-elixir.html
  """

  # how to add a type spec for your functions via @spec.
  @spec plus_one(integer) :: integer
  def plus_one(x), do: x + 1

  # how to create your own type aliases via @type
  @type counter :: integer

  defmodule Person do
    @moduledoc """
    A simple product type to show how to create a struct and define its type
    """
    @type t() :: %__MODULE__{
            first_name: String.t(),
            last_name: String.t()
          }
    defstruct first_name: "Gints", last_name: "Dreimanis"
  end

  defmodule Issue do
    @moduledoc """
    Create a representation of a customized board issue.
    We show how to use a sum type to cover all the state that we want to allow
    """
    # Step 1: Define our struct as normal
    defstruct name: "",
              description: "",
              state: :searching_for_assignee

    # Step 2.1: Create alias to improve readability
    # we can create aliases for the assignee and reviewer.
    @type assignee :: String.t()
    @type reviewer :: String.t()

    # @type state ::
    #     :searching_for_assignee
    #     | {:not_started, String.t()}
    #     | {:in_progress, String.t()}
    #     | {:in_review, String.t(), String.t()}
    #     | {:done, String.t(), String.t()}

    # Step 2.2: Define sum type with other alias we defined previously
    # Such that the above sum type could be improved as
    # Define a sume type for state:
    @type state ::
            :searching_for_assignee
            | {:not_started, assignee}
            | {:in_progress, assignee}
            | {:in_review, assignee, reviewer}
            | {:done, assignee, reviewer}

    # Step 3: Define the type of our struct with @type
    # At last, we could create a type specification for the module by
    @type t() :: %__MODULE__{
            name: String.t(),
            description: String.t(),
            state: state
          }

    # This will show a warning in our code editor to indicate a problem
    # Try our Issue type
    # Create a function that adds a reviewer to the issue with a bug:
    # It will not change the state of the issue.
    @spec add_assignee(Issue.t(), assignee) :: Issue.t()
    def add_assignee(%{state: :searching_for_assignee} = issue, assignee_name) do
      %{issue | state: {:searching_for_assignee, assignee_name}}
    end

    # The correct one to update state
    @spec add_assignee_v2(Issue.t(), assignee) :: Issue.t()
    def add_assignee_v2(%{state: :searching_for_assignee} = issue, assignee_name) do
      %{issue | state: {:not_started, assignee_name}}
    end

    @spec update_to_in_progress(Issue.t(), assignee) :: Issue.t()
    def update_to_in_progress(
          %{state: {:not_started, assignee_name}} = issue,
          assignee_name
        ) do
      %{issue | state: {:in_progress, assignee_name}}
    end

    @spec update_to_review(Issue.t(), reviewer) :: Issue.t()
    def update_to_review(
          %{state: {:in_progress, assignee_name}} = issue,
          reviewer_name
        ) do
      %{issue | state: {:in_review, assignee_name, reviewer_name}}
    end
  end

  # def demo_01() do
  #   # This will show warning and report error because the first parameter should be a Issue struct
  #   Issue.add_assignee_v2(%{name: "issue01", description: "issue01"}, "zw")
  # end

  # def demo_02() do
  #   # This will show no warning and will produce correct result which is:
  #   # %How.Snippets.SumType.Issue{
  #   #   name: "issue01",
  #   #   description: "issue01",
  #   #   state: {:not_started, "zw"}
  #   # }
  #   Issue.add_assignee_v2(%Issue{name: "issue01", description: "issue01"}, "zw")
  # end

  # def demo_03() do
  #   # This will show warning because the compiler could inference that the result of
  #   # add_assignee_v2 doesn't match the type specification from update_to_review:
  #   # Because {:not_started, assignee_name} will never match {:in_progress, assignee_name}
  #   Issue.add_assignee_v2(%Issue{name: "issue01", description: "issue01"}, "zw")
  #   |> Issue.update_to_review("myself")
  # end

  def demo_04() do
    # This will show no warning and complete with result:
    # %How.Snippets.SumType.Issue{
    #   name: "issue01",
    #   description: "issue01",
    #   state: {:in_review, "zw", "myself"}
    # }
    Issue.add_assignee_v2(%Issue{name: "issue01", description: "issue01"}, "zw")
    |> Issue.update_to_in_progress("zw")
    |> Issue.update_to_review("myself")
  end
end
