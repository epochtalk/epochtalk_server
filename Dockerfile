FROM elixir:1.14.0
# install php
RUN curl -sSL https://packages.sury.org/php/README.txt | bash -x
RUN apt update
RUN apt install -y php8.3

# work in /app instead of /
RUN mkdir -p /app
WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force
ADD . .
RUN mix deps.get

# compile for production
ENV MIX_ENV=prod
RUN mix compile

CMD until mix ecto.setup; do sleep 1; done
