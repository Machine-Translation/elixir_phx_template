defmodule [ProjectName]Web.Component.SearchSelect do
  @moduledoc """
  An improved search selection component that is useful when having selections from large lists are necessary
  """

  use [ProjectName]Web, :live_component

  @impl true
  def mount(socket) do
    # max-w-[350px]
    socket =
      socket
      |> assign(class: "")
      |> assign(placeholder: "All")
      |> assign(expanded: false)
      |> assign(highlighted_idx: 0)
      |> assign(can_remove: true)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{options: options, value: value} = assigns

    options = 
      Enum.map(options, fn 
        {label,value} -> {to_string(label), value}
        value -> {to_string(value), value}
      end)

    {term, value} = 
      if value do 
        Enum.find(options, fn {_, v} -> v == value end ) || {nil, nil}
      else 
        {nil, nil}
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(term: term || "")
      |> assign(options: options)
      |> assign(filtered_options: filtered_options(options, nil))

    {:ok, socket}
  end

  @impl true
  def handle_event("focus", _, socket) do
    {:noreply, assign(socket, expanded: true)}
  end

  @impl true
  def handle_event("click_away", _, socket) do
    {:noreply, assign(socket, term: socket.assigns.value, expanded: false)}
  end

  @impl true
  def handle_event("blur", _, socket) do
    {:noreply, assign(socket, term: socket.assigns.value, expanded: false)}
  end

  @impl true
  def handle_event("remove_selected", _, socket) do
    socket =
      socket
      |> assign(value: nil)
      |> assign(term: nil)
      |> assign(filtered_options: filtered_options(socket.assigns.options, nil))
      |> push_event("selected", %{
        value: "",
        id: "#{socket.assigns.id}_container"
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_index", %{}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_index", idx, socket) do
    {index, ""} = Integer.parse(idx)
    {:noreply, assign(socket, highlighted_idx: index)}
  end

  @impl true
  def handle_event("keyup", %{"key" => "Backspace", "value" => term}, socket) do
    socket =
      socket
      |> assign(value: nil)
      |> assign(term: term)
      |> assign(filtered_options: filtered_options(socket.assigns.options, term))
      |> push_event("selected", %{
        value: nil,
        term: term,
        id: "#{socket.assigns.id}_container"
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("keyup", %{"key" => "Enter"}, socket) do
    %{highlighted_idx: highlighted_idx, filtered_options: filtered_options} = socket.assigns
    {term, value} = selected = Enum.at(filtered_options, highlighted_idx) || nil

    socket =
      socket
      |> assign(value: value)
      |> assign(term: term)
      |> assign(expanded: false)
      |> assign(filtered_options: filtered_options(socket.assigns.options, to_string(value)))
      |> push_event("selected", %{
        value: value,
        term: term,
        id: "#{socket.assigns.id}_container"
      })
      |> push_event("js-exec", %{
        to: "##{socket.assigns.id}_main",
        attr: "data-hide-dropdown"
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("keyup", %{"key" => "ArrowDown"}, socket) do
    %{
      highlighted_idx: highlighted_idx,
      options: options
    } = socket.assigns

    highlighted_idx =
      if highlighted_idx + 1 >= length(options), do: highlighted_idx, else: highlighted_idx + 1

    {:noreply, assign(socket, highlighted_idx: highlighted_idx, expanded: true)}
  end

  @impl true
  def handle_event("keyup", %{"key" => "ArrowUp"}, socket) do
    %{highlighted_idx: highlighted_idx} = socket.assigns

    highlighted_idx = if highlighted_idx == 0, do: 0, else: highlighted_idx - 1

    {:noreply, assign(socket, highlighted_idx: highlighted_idx)}
  end

  @impl true
  def handle_event("keyup", %{"value" => term}, socket) do
    socket =
      socket
      |> assign(highlighted_idx: 0)
      |> assign(term: term)
      |> assign(value: nil)
      |> assign(expanded: true)
      |> assign(filtered_options: filtered_options(socket.assigns.options, term))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"selected" => selected}, socket) do
    %{options: options, term: term, id: id} = socket.assigns

    {term, value} = Enum.find(options, fn {_, v} -> to_string(v) == selected end )

    socket =
      socket
      |> assign(value: value)
      |> assign(term: term || "")
      |> assign(filtered_options: filtered_options(options, term))
      |> assign(expanded: false)
      |> push_event("selected", %{
        value: value,
        term: term,
        id: "#{id}_container"
      })
      |> push_event("js-exec", %{
        to: "##{id}_main",
        attr: "data-hide-dropdown"
      })

    {:noreply, assign(socket, value: selected)}
  end

  def show_dropdown(js \\ %JS{}, id) do
    JS.show(js,
      to: "##{id}_container_dropdown",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  # def hide_dropdown(js \\ %JS{}, id) do
  #   JS.hide(js,
  #     to: "##{id}_container_dropdown",
  #     time: 200,
  #     transition:
  #       {"transition-all transform ease-in duration-200",
  #        "opacity-100 translate-y-0 sm:scale-100",
  #        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
  #   )
  # end

  # defp filtered_options(options, nil) do
  #   options
  #   |> Enum.map(fn 
  #     {k, v} -> {k, to_string(v)} 
  #     v -> to_string(v)
  #   end)
  #   |> Enum.take(75)
  # end

  # defp filtered_options(options, term) when is_binary(term) do
  #   options
  #   |> Enum.map(fn 
  #     {k, v} -> 
  #       {k, to_string(v)} 
  #       |> Seqfuzz.filter(term)
  #     v -> 
  #       to_string(v)
  #       |> Seqfuzz.filter(term)
  #   end)
  #   |> Seqfuzz.filter(term)
  #   |> Enum.take(75)
  # end

   defp filtered_options(options, nil) do
    options
    |> Enum.take(75)
  end

  defp filtered_options(options, term) do
    term = to_string(term)

    options
    |> Seqfuzz.filter(term, &(elem(&1, 0)))
    |> Enum.take(75)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class={[@class, "w-full w-full relative"]}
      data-show-dropdown={show_dropdown(@id)}
      data-hide-dropdown={hide_dropdown(@id <> "_container_dropdown")}
      id={"#{@id}_main"}
    >
      <div id={"#{@id}_container"} phx-click={show_dropdown(@id)} phx-hook="SearchSelect">
        <.input field={{@f, @name}} name={@name} value={@value} type="hidden" />
        <div class="mt-1 relative">
          <div class="bg-white relative w-full border border-gray-300 rounded-md shadow-sm px-3 py-1 text-left cursor-default focus:outline-none sm:text-sm flex flex-row">
            <input
              id={@id <> "_label"}
              phx-debounce="50"
              phx-keyup="keyup"
              phx-target={@myself}
              autocomplete="off"
              type="text"
              value={@term}
              placeholder={@placeholder}
              class="border-none focus:outline-none focus:ring-0 flex-grow text-sm"
            />
            <a class="dropdown-icon flex items-center pr-2 cursor-pointer">
              <!-- Heroicon name: solid/selector -->
              <svg
                class="h-5 w-5 text-gray-400"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </a>
          </div>
          <%= if Enum.any?(@filtered_options) do %>
            <ul
              id={"#{@id}_container_dropdown"}
              class={[
                "absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md shadow-2xl py-1 text-sm ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm divide-y divide-gray-100",
                !@expanded && "hidden"
              ]}
              tabindex="-1"
              phx-click-away={hide_dropdown(@id <> "_container_dropdown")}
              phx-click={hide_dropdown(@id <> "_container_dropdown")}
              phx-trarget={@myself}
            >
              <%= for {{label, value}, index} <- Enum.with_index(@filtered_options) do %>
                <li
                  phx-click="select"
                  phx-target={@myself}
                  phx-value-selected={value}
                  phx-value-index={index}
                  data-index={index}
                  class={[
                    "cursor-pointer select-none relative py-2 pl-6 pr-9 text-sm",
                    @highlighted_idx == index && "bg-gray-100"
                  ]}
                >
                  <span class="block truncate">
                    <%= label %>
                  </span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
        <%= if @value && @can_remove do %>
          <div class="absolute top-0 right-0">
            <a
              phx-click="remove_selected"
              phx-target={@myself}
              class="-mt-6 block mt-1 text-blue-700 text-sm hover:underline cursor-pointer"
            >
              Remove selection
            </a>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end