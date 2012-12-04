require "spec_helper"

describe Organization do
  describe "validations" do
    it "is not valid without a name" do
      Organization.new.should_not be_valid
    end

    it "is unique by name" do
      org = Organization.new(name: "orga-1")
      org.should be_valid
      org.save
      Organization.new(name: "orga-1").should_not be_valid
    end
  end
end
