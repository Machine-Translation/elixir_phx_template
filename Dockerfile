FROM elixir:1.15.4

RUN apt-get update && \
    apt-get install -y \
      make \
      g++ \
      git \
      wget \
      curl \
      npm \
      freetds-dev \
      inotify-tools && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG INSTANCE
ENV MIX_ENV $INSTANCE
ENV NODE_ENV production

# Install LTS of nodejs and yarn
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \ 
    npm install -g yarn

# Ensure latest versions of Hex/Rebar are installed on build
RUN mix do local.hex --force, local.rebar --force
    # mix archive.install --force hex phx_new 1.5.9


RUN mkdir /app
WORKDIR /app

# Install deps
COPY mix.exs mix.lock ./
COPY config config
COPY priv priv
COPY lib lib
COPY assets assets
RUN mix deps.get 
RUN mix assets.setup 
RUN mix assets.build

CMD mix phx.server
