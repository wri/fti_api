require "rails_helper"

class UrlValidatable
  include ActiveModel::Validations
  attr_accessor :url
  validates :url, url: true
end

describe UrlValidator do
  subject do
    UrlValidatable.new
  end

  context "invalid input" do
    it "should return false when missing protocol" do
      subject.url = "google.com"
      expect(subject.valid?).to be(false)
      expect(subject.errors[:url]).to include("must start with http:// or https://")
    end

    it "should return false for garbage input" do
      subject.url = "invalid url"
      expect(subject.valid?).to be(false)
      expect(subject.errors[:url]).to include("is invalid")
    end

    it "should return false for URLs without an HTTP protocol" do
      subject.url = "ftp://file.net"
      expect(subject.valid?).to be(false)
      expect(subject.errors[:url]).to include("must start with http:// or https://")
    end
  end

  context "valid input" do
    it "should return true for a correctly formed HTTP URL" do
      subject.url = "http://google.com"
      expect(subject.valid?).to be(true)
    end

    it "should return true for a correctly formed HTTPS URL" do
      subject.url = "https://google.com"
      expect(subject.valid?).to be(true)
    end
  end
end
