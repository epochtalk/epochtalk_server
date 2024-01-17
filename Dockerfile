FROM elixir:1.14.0
# work in /app instead of /
RUN mkdir -p /app
WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force

# compile for production
ENV MIX_ENV=prod
COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
COPY . .
RUN mix compile

CMD until mix ecto.setup; do sleep 1; done
