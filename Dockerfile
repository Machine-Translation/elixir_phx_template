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
RUN mix deps.get && \
    mix deps.compile

# Install assets
COPY assets assets
RUN yarn --cwd assets install

# Compile and digest the app
COPY priv priv
COPY lib lib
RUN mix compile && \
    mix assets.deploy

CMD mix phx.server
