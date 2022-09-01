FROM elixir:1.14.0-rc.0
# work in /app instead of /
RUN mkdir -p /app
WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force
ADD . .
RUN mix deps.get

# enable configuration by environment
COPY config/docker.secret.exs config/prod.secret.exs

# compile for production
ENV MIX_ENV=prod
RUN mix compile

CMD until mix do ecto.create, ecto.migrate; do sleep 1; done
