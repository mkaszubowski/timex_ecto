## Timex Plugin for EctoOne

[![Master](https://travis-ci.org/bitwalker/timex_ecto_one.svg?branch=master)](https://travis-ci.org/bitwalker/timex_ecto_one)
[![Hex.pm Version](http://img.shields.io/hexpm/v/timex_ecto_one.svg?style=flat)](https://hex.pm/packages/timex_ecto_one)

## Getting Started

Learn how to add `timex_ecto_one` to your Elixir project and start using it.

### Adding timex_ecto_one To Your Project

To use timex_ecto_one with your projects, edit your `mix.exs` file and add it as a dependency:

```elixir
def application do
 [ applications: [:timex, ...], ...]
end

defp deps do
  [{:timex, "~> x.x.x"},
   {:timex_ecto_one, "~> x.x.x"}]
end
```

### Adding Timex types to your EctoOne models

```elixir
defmodule User do
  use EctoOne.Model

  schema "users" do
    field :name, :string
    # Stored as an ISO date (year-month-day)
    field :a_date,       Timex.EctoOne.Date # Timex version of :date
    # Stored as an ISO time (hour:minute:second.fractional)
    field :a_time,       Timex.EctoOne.Time # Timex version of :time
    # Stored as an ISO 8601 datetime in UTC (year-month-day hour:minute:second.fractional)
    field :a_datetime,   Timex.EctoOne.DateTime # Timex version of :datetime
    # DateTimeWithTimezone is a special case, please see the `Using DateTimeWithTimezone` section!
    # Stored as a tuple of ISO 8601 datetime and timezone name ((year-month-day hour:minute:second.fractional, timezone))
    field :a_datetimetz, Timex.EctoOne.DateTimeWithTimezone # A custom datatype (:datetimetz) implemented by Timex
  end
end
```

### Using Timex with EctoOne's `timestamps` macro

Super simple! Your timestamps will now be `Timex.DateTime` structs instead of `EctoOne.DateTime` structs.

```elixir
defmodule User do
  use EctoOne.Model
  use Timex.EctoOne.Timestamps

  schema "users" do
    field :name, :string
    timestamps
  end
end
```

### Using with Phoenix

Phoenix allows you to apply defaults globally to EctoOne models via `web/web.ex` by changing the `model` function like so:

```elixir
def model do
  quote do
    use EctoOne.Model
    use Timex.EctoOne.Timestamps
  end
end
```

By doing this, you bring the Timex timestamps into scope in all your models.


## Example Usage

The following is a simple test app I built for vetting this plugin:

```elixir
defmodule EctoOneTest.Repo do
  use EctoOne.Repo, otp_app: :timex_ecto_one_test
end

defmodule EctoOneTest.User do
  use EctoOne.Model
  use Timex.EctoOne.Timestamps

  schema "users" do
    field :name, :string
    field :date_test,       Timex.EctoOne.Date
    field :time_test,       Timex.EctoOne.Time
    field :datetime_test,   Timex.EctoOne.DateTime
    field :datetimetz_test, Timex.EctoOne.DateTimeWithTimezone
  end
end

defmodule EctoOneTest do
  import EctoOne.Query
  use Timex

  alias EctoOneTest.User
  alias EctoOneTest.Repo

  def seed do
    time       = Time.now
    datetime   = Date.now
    datetimetz = Timezone.convert(datetime, "Europe/Copenhagen")
    u = %User{name: "Paul", date_test: datetime, time_test: time, datetime_test: datetime, datetimetz_test: datetimetz}
    Repo.insert!(u)
  end

  def all do
    query = from u in User,
            select: u
    Repo.all(query)
  end
end

defmodule EctoOneTest.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    tree = [worker(EctoOneTest.Repo, [])]
    opts = [name: EctoOneTest.Sup, strategy: :one_for_one]
    Supervisor.start_link(tree, opts)
  end
end
```

And the results:

```elixir
iex(1)> EctoOneTest.seed

14:45:43.461 [debug] INSERT INTO "users" ("date_test", "datetime_test", "datetimetz_test", "name", "time_test") VALUES ($1, $2, $3, $4, $5) RETURNING "id" [{2015, 6, 25}, {{2015, 6, 25}, {19, 45, 43, 457000}}, {{{2015, 6, 25}, {21, 45, 43, 457000}}, "Europe/Copenhagen"}, "Paul", {19, 45, 43, 457000}] OK query=3.9ms
%EctoOneTest.User{__meta__: %EctoOne.Schema.Metadata{source: "users",
  state: :loaded},
 date_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 19, minute: 45,
  month: 6, ms: 457, second: 43,
  timezone: %Timex.TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015},
 datetime_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 19,
  minute: 45, month: 6, ms: 457, second: 43,
  timezone: %Timex.TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015},
 datetimetz_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 21,
  minute: 45, month: 6, ms: 457, second: 43,
  timezone: %Timex.TimezoneInfo{abbreviation: "CEST",
   from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
   offset_std: 60, offset_utc: 60,
   until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}, id: nil,
 name: "Paul", time_test: {1435, 261543, 456856}}
iex(2)> EctoOneTest.all

14:45:46.721 [debug] SELECT u0."id", u0."name", u0."date_test", u0."time_test", u0."datetime_test", u0."datetimetz_test" FROM "users" AS u0 [] OK query=0.7ms
[%EctoOneTest.User{__meta__: %EctoOne.Schema.Metadata{source: "users",
   state: :loaded},
  date_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 0, minute: 0,
   month: 6, ms: 0, second: 0,
   timezone: %Timex.TimezoneInfo{abbreviation: "UTC", from: :min,
    full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015},
  datetime_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 19,
   minute: 45, month: 6, ms: 457.0, second: 43,
   timezone: %Timex.TimezoneInfo{abbreviation: "UTC", from: :min,
    full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015},
  datetimetz_test: %Timex.DateTime{calendar: :gregorian, day: 25, hour: 21,
   minute: 45, month: 6, ms: 457.0, second: 43,
   timezone: %Timex.TimezoneInfo{abbreviation: "CEST",
    from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
    offset_std: 60, offset_utc: 60,
    until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}, id: nil,
  name: "Paul", time_test: {0, 71143, 0}}]
iex(3)>
```

## Additional Documentation

Documentation for Timex and timex_ecto_one are available
[here], and on [hexdocs].

[here]: https://timex.readme.io
[hexdocs]: http://hexdocs.pm/timex_ecto_one/

## License

This project is MIT licended. See the LICENSE file in this repo.

