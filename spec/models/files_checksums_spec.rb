require "spec_helper"

describe "FilesChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should ensure project patch file is up to date" do
    #4.2.9 checksum (the self.allowed_to_condition method is completely overridden and should be reviewed if this test breaks)
    assert_checksum %w(b8ce67efe695bc2381e56db07a0a889e), "app/models/project.rb"
  end

end