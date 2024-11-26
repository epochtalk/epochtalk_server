FROM elixir:1.17.3
# install php
RUN curl -sSL https://packages.sury.org/php/README.txt | bash -x
RUN apt update
RUN apt install -y php8.3

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
