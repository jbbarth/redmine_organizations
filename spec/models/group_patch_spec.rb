require "spec_helper"

describe "Group patch" do
  it "doesn't have a validation on lastname length anymore" do
    name = "a"*100
    Group.where(lastname: name).delete_all
    group = Group.new(lastname: name)
    expect(group).to be_valid
    group.save
    expect(group.reload.name.length).to eq 100
  end
end
