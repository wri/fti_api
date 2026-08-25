module Select2Helper
  def select2(value, options = {})
    select2_container(options[:from]).click # to open the dropdown
    find(:css, "span.select2-container--open li", text: text_matcher(value)).click # find the option and select
  end

  def select2_clear(options = {})
    select2_container(options[:from]).find(:css, "span.select2-selection__clear").click
  end

  def select2_options(options = {})
    container = select2_container(options[:from])
    container.click # to open the dropdown
    results = all(:css, "span.select2-container--open li").map(&:text)
    container.click # to close the dropdown
    results
  end

  def select2_selected_options(options = {})
    container = select2_container(options[:from])
    return container.all(:css, "li.select2-selection__choice").map(&:text) if options[:multiple]

    [container.find(:css, "span.select2-selection__rendered")[:title]]
  end

  private

  def select2_container(label_text)
    find(:css, "label", text: text_matcher(label_text))
      .find(:xpath, "./following-sibling::span[contains(@class, 'select2-container')]")
  end

  # matched by Capybara filters instead of being interpolated into a selector, so values
  # with quotes (like "Cote d'Ivoire") work; case insensitive because labels are uppercased by CSS
  def text_matcher(text)
    /#{Regexp.escape(text)}/i
  end
end
