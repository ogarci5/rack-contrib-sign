
require "spec_helper"

describe Rack::Contrib::Sign do
  describe "#VERSION" do
    it "has a version :)" do
      Rack::Contrib::Sign::VERSION.should_not eq('')
    end
  end
end

