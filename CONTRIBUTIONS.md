# Contribution Guidelines

Before your pull request can be accepted, it must conform to our projects
conventions.  Please refer to these guidelines!

## Responsibilities

* Write tests

  Always write tests.  See [Testing](#Testing) section for best practices.


* Write [code](https://en.wikipedia.org/wiki/Computer_programming)
  in [Elixir](https://elixir-lang.org/) to implement your feature

  (Instructions for your computer to do things)

* Commit code using [Angular Commit Message](https://gist.github.com/brianclements/841ea7bffdb01346392c)
  conventions.

  This is important because this project uses Semantic Release to create
  versioned releases, which requires adherence to Angular Commit conventions.

* Write documentation

  View the [Documentation](#documentation-overview) section of this document for a
  helpful overview.

  See [Writing Documentation](https://hexdocs.pm/elixir/1.13/writing-documentation.html)
  docs for full reference.
  You can even write [Markdown](https://hexdocs.pm/elixir/1.13/writing-documentation.html#markdown)
  inside of your documentation (encouraged :)

  Example types of documentation:

  * Module doc - documentation for an entire module

  * Spec - for all public methods in a module, describes their input and output

  * [Type](#schema-docs) - used with schema to describe the type of data in a model

  * Doc tests - checks that data is manipulated correctly in docs

* Pass tests

  To run tests locally, run this command:

  `mix test`

  This will run all tests in the project.  Tests are also run automatically in
  the CI system on push to GitHub, but this is a good, quick way to make sure
  they're passing without waiting for the entire build and test process to
  finish in CI (which takes a while).

  All tests must pass before code can be merged into the main branch.

* Pass dialyzer

  To run [dialyzer](https://hexdocs.pm/dialyxir/Mix.Tasks.Dialyzer.html)
  locally, run this command:

  `mix dialyzer`

  Dialyzer is a "static analysis tool that identifies software discrepancies"
  in the project and attempts to do things such as; identify code that will
  almost certainly fail, doesn't match the documented spec, or is unreachable.

* Pass static analysis

  This project uses `credo` and `mix format` to ensure that the code submitted
  to our `main` branch is formatted and consistent.

  Our CI workflow runs `mix format --check-formatted` and `mix credo`.  In order
  for a pull request to be accepted, it must pass these checks.

  For formatting, simply run `mix format` before submitting a pull request and
  commit the changes.

  For credo, you can run `mix credo` locally.  This tool will analyze the code
  you wrote and suggest changes.  View the suggestions and update your code
  accordingly; any result other than a `design` issue will cause the CI workflow
  to fail when submitting pull requests, so be sure to address all other
  concerns!

* Pass CI tests/build

  Any time code is pushed to this repo, our CI system will automatically run
  tests and attempt to build the project for production release.  When viewing
  the branch on GitHub, it will either show up as test/CI `passing` or `failed`.

  Code that doesn't pass the tests and CI build will not be merged!  Please view
  the results and fix your code accordingly.  If you have any questions or get
  stuck, feel free to submit an issue to this project for help.

* Submit a pull request

  Once your code is ready, submit a pull request and an internal team member
  will review your changes.  We'll list any suggestion for improvements or fixes
  in the comments on the pull request.  Once all concerns are addressed and
  changes are approved, the PR will be merged into our codebase.

  Release tags are updated via Semantic Release, which analyzes commits with
  Angular Commit message convention and selects an appropriate version to
  release on GitHub.


## Testing

Motivational notes on testing:
```
Always test code.

Testing ensures that features work as intended without requiring a manual check
every time code is updated.  It improves the stability and maintainability of
the project, which saves developers time and reduces frustration.

Occasionally, you can uncover a bug or come up with a new idea for improving a
feature - but AT THE VERY LEAST, well-written tests will ensure that a feature
you wrote works now and will keep working in the future.

A small time investment in testing today will save you countless hours in the
future.
```

Our testing best practices are based off of [nimble's best practices](https://nimblehq.co/compass/development/code-conventions/elixir/ex-unit/).
You can read their documentation as long as the link is good - it should take
around 5 minutes, as there really isn't much.

Anyhow, here is a regurgitation of it with additional amendments...


### Naming & Structure

Place all test files under the `test/` directory, in the same structure as they
appear in the `lib/` directory; this makes it easy to find the corresponding
code file when a test fails.


### Authentication/Banning/Malicious

If you need a handle on seeded `User` info in a test that uses `ConnCase`, you
can grab it from the context map, which contains three users under
`context.users` and their attributes under `context.user_attrs`.  Refer to the
implementation in [conn_case.ex](test/support/conn_case.ex) for more details.

Ex:
```
test "finds user's posts", %{conn: conn, users: %{user: user}} do
  posts = Post.by_user(user)
  ...
end
```

To authenticate a request in a `ConnCase` test, use the `@authenticated` tag.
This will authenticate the `conn` and provide authed user info in the context

```
# user
@tags :authenticated
# admin
@tags authenticated: :admin
# super admin
@tags authenticated: :super_admin
...
%{
  authed_user: authed_user,
  token: token,
  authed_user_attrs: authed_user_attrs
} = context
```

For a handle on a banned or malicious user, use the tags `:banned` and
`:malicious`.  These will convert the `user` in `context.users` into a banned
or malicious user and provide either `malicious_user_changeset` or
`banned_user_changeset` in `context`.

```
@tags :banned
...
%{banned_user_changeset: banned_user_changeset} = context

OR

@tags :malicious
...
%{malicious_user_changeset: malicious_user_changeset} = context
```


### Seeding

Refrain from adding more `test/seed/` files.  Currently, `User` seed is there
because all tests use users for authentication and user creation is expensive.

Seeding creates interdependency between tests.  One test may expect data to be
there in order to work, and another may need there to be no data first.
Instead of seeding, please use [Factories](#Factories) and setup functions.


### Data/Conn/Channel Case

Use `async: true` by default when using cases.  If a test won't work with async
set to true, include a `moduledoc` with a reason why.

For example, our `Session` tests use Redis, which is not automatically reset
once a test finishes.  Because of this, they cannot be run in async mode.  There
is a `moduledoc` included, explaining this.


### Formatting

When a test fails, we'll need to know which test broke and why.  Writing
descriptions and test names in a useful way can help us determine these details.


#### Descriptions

Describe tests by the function and arity they are testing.  If a describe block
is too long, you can break them down into seperate describe blocks, adding
context after the arity.

```
describe "create/1" do

...

describe "page/1, action types" do
describe "page/1, mod_id" do
```


#### Test names

Use `given`, `with`, or `when` to describe test preconditions.  If multiple
preconditions are necessary, compound them.

```
describe "create/1" do
  test "given valid input, creates a thread" do
  ...
  test "given valid input, when a user is logged in, creates a thread" do
  ...
  test "given valid input, when a user is not logged in, errors with unauthenticated" do
end
```

#### Assertions

The data being tested should be on the left hand side of an assert expression;
the expected value should be on the right hand side.

Do not use pattern matching (`=`) to check values on data structures.  Instead,
assure exact matches by explicitly checking the entire data structure, or by
extract values from it before checking equality with `==`

```
assert result == %{key: value, other_key: other_value}
assert result.key == value
assert result.other_key == other_value
```

Use `==` when checking `nil`, `true`, and `false` to assure exact matches.


### Factories

When testing, it is necessary to generate some generic data to test on.
Factories provide this functionality, and are located in the
`test/support/factories/` directory.  You can add a new factory or modify an
existing one there.  When adding a new factory, you also need to `use` it in
`test/support/factory.ex` for it to be available in †he tests.

This project currently uses `thoughtbot/ex_machina`(https://github.com/thoughtbot/ex_machina)
for factory functionality.  This repo is no longer maintained by thoughtbot, so
whatever extra functionality we need, we must implement ourselves.

Many models implement their own `create` methods, so they can't be created using
`ex_machina`'s insert().  Instead, use build() and take in options to specify
model attributes.


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
