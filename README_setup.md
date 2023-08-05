# Note on setup
It is assumed that this is a new repository created from the template Elixir Phoenix repository made by [Machine Translation](https://machtranspro.com). After completing the below commands, this file can be deleted as Phoenix will generate a new repository README file to replace this one. This file is named differently as the new README will be generated at the very start of setup, so it would overwrite this file too soon.

# What this template comes with
This template comes with multiple setup and test files to have the baseline needs for an Elixir Phoenix server.
1. Test files (`docker-compose.test.yml` and `Dockerfile.test`) for running tests in GitHub workflows
2. Production `Dockerfile`
3. Development files (`docker-compose.yml` and `Dockerfile.dev`) for running locally
4. `.github` folder that has testing workflows set up to run on push and dependabot to keep tools up-to-date
5. `extra_files` folder that has starting points for common css and Phoenix components

# Preliminary setup
Before running setup commands below, you must find and replace all instances of `[project_name]` and `[ProjectName]` within the repository. If working within VS Code, you can find-all-and-replace within the whole repository by clicking `ctrl + shift + h`. If you have one of the values highlighted within the `mix phx.new ...` command below and press the shortcut keys then it will autofill the find box with what you have highlighted.

# Setup commands
Run the below commands in the order that they appear. Do not run more than 1 command at a time as they must happen sequentially.

``` bash
# Everything tabbed over is within the docker container
docker-compose run app /bin/bash
    mix local.hex
    mix archive.install hex phx_new
    mix phx.new . --app [project_name] --module [ProjectName]

# Then set up the local DB in `config/dev.exs` based on the password found in the `docker-compose.yml` file

    mix ecto.create

# ================Add the following to the `mix.exs` file==================
# Add Credo (Code analysis tool for code consistency): {:credo, "~> 1.6", only: [:dev, :test], runtime: false}

# Add Dialyxir (Code analysis tool for hidden warnings/errors): {:dialyxir, "~> 0.4", only: [:dev]}

# Add EX Doc (Elixir documentation tool): {:ex_doc, "~> 0.27", only: :dev, runtime: false}

# (Optional) Add Oban (For background jobs): {:oban, "~> 2.14"}

# Finish EX Doc installation guide: https://github.com/elixir-lang/ex_doc

    mix setup

# If installed, add Oban requirements: https://hexdocs.pm/oban/installation.html
```

# Post setup
1. Go to `config/dev.exs` and go to `config :[project_name] [ProjectName]Web.Endpoint, http: [ip: {}...]...`. The `ip` variable should be `{127, 0, 0, 1}`. This needs to be changed to `{0, 0, 0, 0}` so that browsers can access the server outside of the Docker container.

2. Make sure to change the database password for the dev and test databases to NOT be `postgres`:
    * Change dev: `docker-compose.yml` has 2 places that need the password changed and `config/dev.exs` needs the password changed in `config :[project_name], [ProjectName].Repo, ..., password: [password]` field.
    * Change test: `docker-compose.test.yml` has 2 places that need the password changed and `config/test.exs` needs the password changed in `config :[project_name], [ProjectName].Repo, ..., password: [password]` field.

3. Put extra files where they belong:
    * `extra_files/assets/css/*` -> `assets/css/`. Replace `app.css` in `assets/css/` with the given one as there is baseline css for the application.
    * `extra_files/components/*` -> `lib/[project_name]_web/components`. Replace `core_components.ex` in the `lib` folder as the given one has extra components.
    * `extra_files/utils` -> `lib/[project_name]/utils`. This utils folder needs to be copied to the `lib` location.