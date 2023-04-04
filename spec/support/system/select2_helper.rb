module Select2Helper
  def select2(value, options = {})
    # Find the select2 container
    container = find(:xpath, "//label[contains(text(), '#{options[:from]}')]/following-sibling::span[contains(@class, 'select2-container')]")
    container.click # to open the dropdown
    container.find(:xpath, "//span[contains(@class, 'select2-container--open')]//li[contains(text(), '#{value}')]").click # find the option and select
  end

  def select2_clear(options = {})
    container = find(:xpath, "//label[contains(text(), '#{options[:from]}')]/following-sibling::span[contains(@class, 'select2-container')]")
    container.find(:xpath, ".//span[contains(@class, 'select2-selection__clear')]").click
  end

  def select2_options(options = {})
    container = find(:xpath, "//label[contains(text(), '#{options[:from]}')]/following-sibling::span[contains(@class, 'select2-container')]")
    container.click # to open the dropdown
    results = container.all(:xpath, "//span[contains(@class, 'select2-container--open')]//li").map(&:text)
    container.click # to close the dropdown
    results
  end

  def select2_selected_options(options = {})
    container = find(:xpath, "//label[contains(text(), '#{options[:from]}')]/following-sibling::span[contains(@class, 'select2-container')]")
    return container.all(:xpath, ".//li[contains(@class, 'select2-selection__choice')]").map(&:text) if options[:multiple]

    [container.find(:xpath, ".//span[contains(@class, 'select2-selection__rendered')]")[:title]]
  end
end
