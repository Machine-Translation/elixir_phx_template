# Note on setup
It is assumed that this is a new repository created from the template Elixir Phoenix repository made by [Machine Translation](https://machtranspro.com). After completing the below commands, this file can be deleted as Phoenix will generate a new repository README file to replace this one. This file is named differently as the new README will be generated at the very start of setup, so it would overwrite this file too soon.

# What this template comes with
This template comes with multiple setup and test files to have the baseline needs for an Elixir Phoenix server.
1. Test files (`docker-compose.test.yml` and `Dockerfile.test`) for running tests in GitHub workflows
2. Production `Dockerfile`
3. Development files (`docker-compose.yml` and `Dockerfile.dev`) for running locally
4. `extra_files` folder that has starting points for common css and Phoenix components

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
    exit
```

Make sure you then properly set up the postgres password. Start up your containers with `docker-compose up` in 1 terminal. Then, in another terminal, run the following command.

``` bash
docker exec -i [db container id] psql -U postgres -c "ALTER USER postgres PASSWORD '<new-password>';"
```

Now stop the running containers. Then, go into `config/dev.exs` and `config/test.exs` and make sure the Repo config looks like it does below. It makes sure that the values we set in the docker-compose yml files are used and so we do not have hardcoded passwords in elixir code.

``` elixir
config :predicting_resistance, [ProjectName].Repo,
  username: System.get_env("DATABASE_USERNAME") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "",
  hostname: System.get_env("DATABASE_HOSTNAME") || "localhost",
  database: "predicting_resistance_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

Now you should be able to continue creating the database and finishing setup.

``` bash
docker-compose run app /bin/bash
    mix ecto.create

# ================Add the following to the `mix.exs` file==================
# Add Credo (Code analysis tool for code consistency): {:credo, "~> 1.6", only: [:dev, :test], runtime: false}

    # Generate credo configuration (https://hexdocs.pm/credo/config_file.html)
    mix credo gen.config

# Add Dialyxir (Code analysis tool for hidden warnings/errors): {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}

# Finish installation of Dialyxir (https://hexdocs.pm/dialyxir/readme.html#installation)
# You should have updated mix.exs and .gitignore

# Add SeqFuzz (Tool to fuzzy search strings in list): {:seqfuzz, "~> 0.2.0"}

# NOTE THAT EX Doc MUST appear in the mix.exs list after SeqFuzz due to dependency conflicts
# Add EX Doc (Elixir documentation tool): {:ex_doc, "~> 0.27", only: :dev, runtime: false, override: true}

# (Optional) Add Oban (For background jobs): {:oban, "~> 2.14"}

# Finish EX Doc installation guide: https://github.com/elixir-lang/ex_doc

    mix setup

# If installed, add Oban requirements: https://hexdocs.pm/oban/installation.html
```

# Post setup
1. Go to `config/dev.exs` and go to `config :[project_name] [ProjectName]Web.Endpoint, http: [ip: {}...]...`. The `ip` variable should be `{127, 0, 0, 1}`. This needs to be changed to `{0, 0, 0, 0}` so that browsers can access the server outside of the Docker container.

2. Put extra files where they belong:
    * `extra_files/assets/css/*` -> `assets/css/`. Replace `app.css` in `assets/css/` with the given one as there is baseline css for the application.
    * `extra_files/components/*` -> `lib/[project_name]_web/components`. Replace `core_components.ex` in the `lib` folder as the given one has extra components.
    * `extra_files/utils` -> `lib/[project_name]/utils`. This utils folder needs to be copied to the `lib` location.
    * Run `sudo mv extra_files/.github/ .`. This `.github` folder that has testing workflows set up to run on push and dependabot to keep tools up-to-date. It will move the folder to the main repository directory for GitHub to find.

3. Choose how you would like to run your GitHub workflows. There are 2 push workflows made. One is set up to run on a self-hosted runner and the other is made to run on a GitHub runner. Choose which one will be the best fit for your repository and delete the other. **NOTE:** It is prefered to use a self-hosted runner for efficiency of workflow and layout of jobs over steps. However, if the repository is public, then it is prefered to use a GitHub runner as anyone can try running code on your self-hosted machine.

4. Credo will fail if you do not add `@moduledoc` tag for the following files. You can either add documentation for these files, or put `@moduledoc false`.
    * `lib/predicting_resistance_web/telemetry.ex`
    * `lib/predicting_resistance_web/components/layouts.ex`
    * `lib/predicting_resistance/mailer.ex`

5. The format test will error next as code from the generated templates. You will need to run `mix format` in the docker container to format all files to fix this.

6. Lastly, dialyzer will fail at first unless you tell it to add ex_unit. You need to make sure that your `mix.exs` file has the following under the `project` function.
    ``` elixir
    dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        check_plt: true,
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
    ```