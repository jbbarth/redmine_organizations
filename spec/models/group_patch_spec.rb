require "spec_helper"

describe "Group patch" do
  it "doesn't have a validation on lastname length anymore" do
    name = "a"*100
    Group.where(lastname: name).delete_all
    group = Group.new(lastname: name)
    group.should be_valid
    group.save
    group.reload.name.length.should == 100
  end
end
