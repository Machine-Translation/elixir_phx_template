defmodule TestingWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import TestingWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      data-show-modal={show_modal(@id)}
      data-hide-modal={hide_modal(@id)}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week
               search_select checkboxes radios)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end
  

  def input(%{type: "search_select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <.live_component
        module={[ProjectName]Web.Component.SearchSelect}
        id={@id || @name}
        f={@f}
        name={@name}
        value={@value}
        options={@options}
        can_remove={@can_remove}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "checkboxes"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="field">
      <.label for={@id}><%= @label %></.label>
      <fieldset class="grid grid-cols-4 gap-2 mt-2 mb-2">
        <%= for {item, value} <- @options do %>
          <label class="flex flex-row items-center space-x-2 ">
            <input
              type="checkbox"
              class="rounded border-zinc-300 text-primary-500 focus:ring-primary-500"
              name={@name}
              value={value}
              checked={Enum.member?(assigns.value || [], value)}
            />
            <span class="text-gray-500 text-base"><%= item %></span>
          </label>
        <% end %>
      </fieldset>

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radios"} = assigns) do
    assigns = assign_new(assigns, :options, fn -> [{"Yes", true}, {"No", false}] end)

    ~H"""
    <div phx-feedback-for={@name} class="field">
      <.label for={@id}><%= @label %></.label>
      <fieldset class="grid grid-cols-4 gap-2 mt-2 mb-2">
        <%= for {k,v} <- @options do %>
          <label class="flex flex-row items-center space-x-2 ">
            <input
              type="radio"
              class="rounded border-zinc-300 text-primary-500 focus:ring-primary-500"
              name={@name}
              value={v |> to_string()}
              checked={@value |> to_string() == v |> to_string()}
            />
            <span class="text-gray-500 text-base"><%= k %></span>
          </label>
        <% end %>
      </fieldset>

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Creates a dropdown that can have multiple buttons/links

  ## Examples

    <.dropdown id="options" :let={[toggle: toggle]}>
      <.dropdown_button label="Print & Export" toggle={toggle} />
      <:content>
        <a href={~p"..."}
          target="_blank"
        >
          <div class="flex flex-row">
            Button 1
          </div>
        </a>
        
        <a href={~p"..."}
          target="_blank"
        >
          <div class="flex flex-row">
            Button 2
          </div>
        </a>
      </:content>
    </.dropdown>

    <.dropdown id="options" label="Print & Export">
      <:content>
        <a href={~p"..."}
          target="_blank"
        >
          <div class="flex flex-row">
            Button 1
          </div>
        </a>
        
        <a href={~p"..."}
          target="_blank"
        >
          <div class="flex flex-row">
            Button 2
          </div>
        </a>
      </:content>
    </.dropdown>
  """
  attr :id, :string, required: true
  attr :label, :string, default: nil

  slot :inner_block, required: true
  slot :content

  def dropdown(assigns) do
    ~H"""
    <div class="relative inline-block text-left" phx-click-away={hide_dropdown(@id)}>
      <%= if is_nil(@label) do %>
        <%= render_slot(@inner_block, toggle: toggle_dropdown(@id)) %>
      <% else %>
        <.dropdown_button label={@label} toggle={toggle_dropdown(@id)} />
      <% end %>

      <div
        id={@id}
        class="dropdown hidden absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
      >
        <%= render_slot(@content, toggle: toggle_dropdown(@id)) %>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :default_js, :JS, required: true
  attr :default_value, :any, required: true
  attr :default_label, :string, required: true

  slot :menu

  @doc """
  Creates a dropdown that has a button attached to it.
  
  This can be used as a dropdown with a default button to make
  navigation easier for users.

  # Examples

    <.dropdown_with_button
      id="dropdown-id"
      default_js={JS.push("button_clicked", target: @myself)}
      default_value="yes"
      default_label="default button"
    >
      <:menu>
        <a 
          phx-click={JS.push("button_1", target: @myself)}
          phx-value-result="no"
          role="menuitem"
          tabindex="-1"
        >
          <div class="flex flex-row">
            Inner Button 1
          </div>
        </a>
      </:menu>
    </.dropdown_with_button>
  """
  def dropdown_with_button(assigns) do
    ~H"""
    <div class="inline-flex rounded-md shadow-sm" phx-click-away={hide_dropdown(@id)}>
      
      <button
        type="button"
        phx-click={@default_js}
        phx-value-result={@default_value}
        class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
      >
        <%= @default_label %>
      </button>

      <div class="relative -ml-px block">
        <button
          type="button"
          class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          id={"#{@id}-option-menu-button"}
          aria-expanded="true"
          aria-haspopup="true"
          phx-click={toggle_dropdown(@id)}
        >
          <span class="sr-only">Open options</span>
          <!-- Heroicon name: mini/chevron-down -->
          <svg
            class="h-5 w-5"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
              clip-rule="evenodd"
            />
          </svg>
        </button>

        <div
          id={@id}
          class="dropdown hidden absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        >
          <%= render_slot(@menu) %>
        </div>
      </div>
    </div>
    """
  end

  attr :toggle, :any, required: true
  attr :label, :string, default: "Options"
  slot :inner_block

  def dropdown_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-100"
      phx-click={@toggle}
    >
      <%= if @inner_block == [] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
      <!-- Heroicon name: mini/chevron-down -->
      <svg
        class="-mr-1 ml-2 h-5 w-5"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="currentColor"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
          clip-rule="evenodd"
        />
      </svg>
    </button>
    """
  end

  ## JS Commands

  def hide_dropdown(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def toggle_dropdown(js \\ %JS{}, id) do
    js
    |> JS.toggle(
      to: "##{id}",
      in:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"},
      out:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  @doc """
  Formats Datetime variables to a string to show on a webpage.

  ## Examples

    <.moment date={record.inserted_at} />
    <.moment date={record.inserted_at} show_time={false} />
    <.moment date={version.recorded_at} show_time={true} include_timezone={true} />
  """
  attr :format, :string
  attr :date, :any, required: true
  attr :show_time, :boolean, default: false
  attr :include_timezone, :boolean, default: false

  def moment(%{format: _format} = assigns) do
    ~H"""
    <%= format_datetime(@date, @format) %>
    """
  end

  def moment(assigns) do
    ~H"""
    <%= if @show_time do %>
      <%= format_datetime(@date, "%d%b%y") %> at <%= format_datetime(
        @date,
        maybe_add_timezone("%I:%M%p", @include_timezone)
      ) %>
    <% else %>
      <%= format_datetime(@date, "%d%b%y") %>
    <% end %>
    """
  end

  ## JS Commands

  defp format_datetime(datetime, format) do
    # Ecto stores datetimes in naive format/UTC time, so we can convert that to DateTime with a proper timezone.
    DateTime.from_naive!(datetime, "Etc/UTC")
    |> DateTime.shift_zone!("America/Chicago")
    |> Calendar.strftime(format)
  end

  defp maybe_add_timezone(format, include_timezone) do
    if include_timezone do
      format <> " %Z"
    else
      format
    end
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
  

  def push_hide_modal(socket, id) do
    Phoenix.LiveView.push_event(socket, "js-exec", %{
      to: "##{id}",
      attr: "data-hide-modal"
    })
  end

  def push_show_modal(socket, id) do
    Phoenix.LiveView.push_event(socket, "js-exec", %{
      to: "##{id}",
      attr: "data-show-modal"
    })
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  A tooltip component that allows a tooltip 
  to appear over a target.

  ## Example

  <.tool_tip>
    <:target>
      Text that, when hovered over, will show tooltip
    </:target>
    <:tooltip>
      Tooltip text that will appear.
    </:tooltip>
  </.tool_tip>
  """
  attr :class, :string, default: ""

  slot :target, required: true
  slot :tooltip, required: true

  def tool_tip(assigns) do
    ~H"""
    <div class={["tooltip", @class]}>
      <%= render_slot(@target) %>
      <div class="tooltip-text">
        <%= render_slot(@tooltip) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an informational pill.

  This is an efficient way to give a small piece of information to
  the user that can be quickly digestible if it is good, bad, warning, etc.

  ## Examples

    <.pill color="red" size="medium">
      This is a pill
    </.pill>
    <.pill color="red" size="medium" label="This is a pill" />
  """
  attr :class, :string, default: nil
  attr :size, :string, default: "medium"
  attr :color, :string, default: "gray"
  attr :label, :string, default: nil

  slot :inner_block

  def pill(assigns) do
    %{size: size, color: color} = assigns

    size_css =
      case size do
        "small" -> "text-sm px-3 py-1 font-medium"
        "medium" -> "text-base px-4 py-1 font-medium"
        "large" -> "text-xl px-9 py-3 font-bold"
        "xlarge" -> "text-xl px-9 py-3 font-bold"
      end

    color_css =
      case color do
        "red" -> "!bg-red-200 !text-red-900"
        "black" -> "!bg-black !text-white"
        "green" -> "!bg-green-200 !text-green-900"
        "yellow" -> "!bg-yellow-200 !text-yellow-900"
        "blue" -> "!bg-blue-300 !text-blue-900"
        "white" -> "!bg-white !text-gray-900"
        "gray" -> "!bg-gray-100 !text-gray-900"
        "dark-gray" -> "!bg-gray-300 !text-gray-900"
        "orange" -> "!bg-orange-300 !text-orange-900"
      end

    assigns =
      assigns
      |> assign(size_css: size_css)
      |> assign(color_css: color_css)

    ~H"""
    <span class={["mr-1 mb-1 rounded-full", @size_css, @color_css, @class]}>
      <%= if @inner_block != [] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :table_class, :string, default: nil
  attr :queryable, :any, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 25
  attr :prefix, :any, default: nil
  attr :now, :any, default: nil
  attr :preload, :list, default: []
  attr :repo, :any, default: [ProjectName].Repo
  attr :paginate, :string

  slot :header, required: true
  slot :row, required: true

  def paged_table(assigns) do
    %{
      queryable: queryable,
      preload: preload,
      page: page,
      prefix: prefix,
      per_page: per_page,
      repo: repo
    } = assigns

    paged =
      [ProjectName].Utils.Paged.paginate(queryable,
        preload: preload,
        prefix: prefix,
        page: page,
        per_page: per_page,
        repo: repo
      )

    assigns = assign(assigns, paged: paged)

    ~H"""
    <section class={["w-full", @class]}>
      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />

      <div class={[
        "overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg",
        @table_class
      ]}>
        <table class="table">
          <thead>
            <%= render_slot(@header) %>
          </thead>
          <tbody>
            <%= for record <- @paged.records do %>
              <%= render_slot(@row, record) %>
            <% end %>
          </tbody>
        </table>
      </div>

      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />
    </section>
    """
  end
  
  attr :class, :string, default: nil
  attr :table_class, :string, default: nil
  attr :queryable, :any, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 25
  attr :prefix, :any, default: nil
  attr :preload, :list, default: []
  attr :repo, :any, default: [ProjectName].Repo
  attr :paginate, :string

  slot :inner_block, required: true

  def paged_records(assigns) do
    %{
      queryable: queryable,
      preload: preload,
      page: page,
      prefix: prefix,
      per_page: per_page,
      repo: repo
    } = assigns

    paged =
      [ProjectName].Utils.Paged.paginate(queryable,
        preload: preload,
        prefix: prefix,
        page: page,
        per_page: per_page,
        repo: repo
      )

    assigns = assign(assigns, paged: paged)

    ~H"""
    <section class={["w-full", @class]}>
      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />

      <%= render_slot(@inner_block, @paged.records) %>

      <%= if @paged.total_count > 0 do %>
        <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />
      <% end %>
    </section>
    """
  end

  attr :paged, :any, required: true
  attr :page, :integer, required: true
  attr :paginate, :string, required: true

  def paged_pagination(assigns) do
    ~H"""
    <nav class="py-3 flex items-end justify-between">
      <div class="hidden sm:block">
        <p class="text-sm text-gray-700">
          Showing <span class="font-medium"><%= @paged.starting_at %></span>
          to <span class="font-medium"><%= @paged.ending_at %></span>
          of <span class="font-medium"><%= @paged.total_count %></span>
          results
        </p>
      </div>
      <div class="flex-1 flex justify-between sm:justify-end">
        <%= if @page > 1 do %>
          <a
            phx-click={@paginate}
            phx-value-page={@page - 1}
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
          >
            Previous
          </a>
        <% end %>
        <%= if @paged.ending_at != @paged.total_count do %>
          <a
            phx-click={@paginate}
            phx-value-page={@page + 1}
            class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
          >
            Next
          </a>
        <% end %>
      </div>
    </nav>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(TestingWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(TestingWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
