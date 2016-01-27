module ApplicationHelper
  # Set class on active navigation items
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    controller_matches = recognized[:controller] == params[:controller]
    action_matches = recognized[:action] == params[:action]

    if controller_matches && action_matches
      content_tag(:li, class: "active") do
        link_to(text, link)
      end
    else
      content_tag(:li) do
        link_to(text, link)
      end
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : "sortable"
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.merge({sort: column, direction: direction}), {class: css_class}
  end
end
