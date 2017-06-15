module ValidationHelper

  # Returns true if it gets a list of ids divided by commas
  def self.ids?(ids)
    /(\d)+(,(\d)+)*$/ === ids
  end
end