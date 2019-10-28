# Since we will have multiple worker processes running parallely for calculating
# hashes of files we need a Supervisor for these worker.
# Now the number of worker our supervisor has to manage is dynamic and also
# we must have the ability to add a worker dynamically during runtime.
# For these reasons we use a DynamicSupervisor instead of a regular GenServer here.

# The start_link function works the same in a supervisor as it does in a GenServer.start
# it is called to start the server containing the supervisor code. Inside this server,
# Elixir automatically calls the init callback, which in turn initializes the supervisor
# code itself. This initialization receives the supervisor options. In the case of a
# dynamic supervisor, this can only be strategy: one_for_one.

defmodule Duper.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # This calls the supervisor, telling it to
  # add another child based on the child specification we pass. In this case, we tell it
  # to start Duper.Worker. A new server is created for each call, and these servers run
  # in parallel.

  # The below method is used by our gathrer server to add workers

  def add_worker() do
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, Duper.Worker)
  end
end
