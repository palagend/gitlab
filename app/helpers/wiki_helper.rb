module WikiHelper
  # Produces a pure text breadcrumb for a given page.
  #
  # page_slug - The slug of a WikiPage object.
  #
  # Returns a String composed of the capitalized name of each directory and the
  # capitalized name of the page itself.
  def breadcrumb(page_slug)
    page_slug.split('/')
      .map { |dir_or_page| WikiPage.unhyphenize(dir_or_page).capitalize }
      .join(' / ')
  end

  def wiki_breadcrumb_dropdown_links(page_slug)
    page_slug_split = page_slug.split('/')
    page_slug_split.pop(1)
    current_slug = ""
    page_slug_split
      .map do |dir_or_page|
        current_slug = "#{current_slug}#{dir_or_page}/"
        add_to_breadcrumb_dropdown link_to(WikiPage.unhyphenize(dir_or_page).capitalize, project_wiki_path(@project, current_slug)), location: :after
      end
  end

  def page_current_dir(wiki, page_slug, includes_filename: true)
    dir = includes_filename ? wiki.page_title_and_dir(page_slug).pop : page_slug

    WikiPage.unhyphenize(dir)
  end
end
