require "spec_helper"

describe "Group patch" do
  it "doesn't have a validation on lastname length anymore" do
    group = Group.new(lastname: "a"*100)
    group.should be_valid
    group.save
    group.reload.name.length.should == 100
  end
end
