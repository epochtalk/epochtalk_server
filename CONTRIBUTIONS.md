# Contribution Guidelines

Before your pull request can be accepted, it must conform to our projects
conventions.  Please refer to these guidelines!


## Responsibilities

* Write tests

  Write a test that will pass once your code is implemented correctly;
  it should fail at first.  Be mindful of edge cases and add test cases
  accordingly.

* Write [code](https://en.wikipedia.org/wiki/Computer_programming)
  in [Elixir](https://elixir-lang.org/) to implement your feature

  (Instructions for your computer to do things)

* Commit code using [Angular Commit Message](https://gist.github.com/brianclements/841ea7bffdb01346392c)
  conventions.

* Write documentation

  View the [Documentation](#Documentation overview) section of this document for a
  helpful overview.

  See [Writing Documentation](https://hexdocs.pm/elixir/1.13/writing-documentation.html)
  docs for full reference.
  You can even write [Markdown](https://hexdocs.pm/elixir/1.13/writing-documentation.html#markdown)
  inside of your documentation (encouraged :)

  Example types of documentation:

  * Module doc - documentation for an entire module

  * Spec - for all public methods in a module, describes their input and output

  * [Type](#Schema docs) - used with schema to describe the type of data in a model

  * Doc tests - checks that data is manipulated correctly in docs

* Pass tests

  `mix test`

* Pass dialyzer

  `mix dialyzer`

* Pass CI tests/build


## Documentation overview


### Schema docs

For Models (with schema)

`@type t::%__MODULE__{}`

Using the standard name `t` for `@type` specifying what comes out of this
model; this is what will be generated when you create a new one from the
constructor (ie. `%User{}` or `%User{username: "newuser"})`)

If you know a better word for "constructor", please submit a documentation pull
request.

For a `@type` documentation, ExDoc will generate `term()` for all unspecified
fields, which matches all values.  You can overload the field to specify the
type, using `| term()` or `| nil` in case an empty model is needed.

In this example, the User model has a field called preferences, which is an
[Ecto association](https://hexdocs.pm/ecto/2.2.11/associations.html) that
references the Preference Model.  When running dialyzer, the association to
Preference is not automatically preloaded.  Here, we use `| term()` to get it to
match any value?

When you call changeset you pass an empty User model and a map of attributes to
populate the model with.  Initially, the User model is empty and dialyzer checks
all code paths, so it's running the changeset function and there's an empty user

If type doesn't handle empty, then it will error.

Use `| term()` for associations, database relationship in ecto.

```elixir
defmodule EpochtalkServer.Models.User do
  ...
  alias EpochtalkServer.Models.Preference

...

@type t::%__MODULE__{
  [auto_generated_field]: term(),
  id: non_neg_integer | nil,
  email: String.t() | nil,
  preferences: Preference.t() | term()

  ...
}
schema "users" do
...
```
