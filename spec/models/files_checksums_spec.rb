require "spec_helper"

describe "FilesChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should ensure project patch file is up to date" do
    # 6.0.1 & 5.1.4 checksum (the self.allowed_to_condition method is completely overridden and should be reviewed if this test breaks)
    assert_checksum %w(40b18f67d953eda5041ac5c20233b784 d3b53e9654bfdd6969c69d7ea7852cf8 b8ce67efe695bc2381e56db07a0a889e a11cce5462e20a51064f9a72834ac527), "app/models/project.rb"
  end

end
