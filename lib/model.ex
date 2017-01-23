defmodule Timex.EctoOne.Timestamps do
  @moduledoc """
  Provides a simple way to use Timex with EctoOne timestamps.

  # Example

  ```
  defmodule User do
    use EctoOne.Model
    use Timex.EctoOne.Timestamps

    schema "user" do
      field :name, :string
      timestamps
    end
  ```

  For potentially easier use with Phoenix, add the following in `web/web.ex`:

  ```elixir
  def model do
    quote do
      use EctoOne.Model
      use Timex.EctoOne.Timestamps
    end
  end
  ```

  This will bring Timex timestamps into scope in all your models

  """

  @default_timestamps_opts [type: Timex.EctoOne.DateTime]
  defmacro __using__(opts) do
    quote do
      @timestamps_opts unquote(Dict.merge(opts, @default_timestamps_opts))
    end
  end
end