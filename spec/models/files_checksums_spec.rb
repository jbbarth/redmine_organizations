require "spec_helper"

describe "FilesChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should ensure project patch file is up to date" do
    # 6.0 & 6.1 checksums (the self.allowed_to_condition method is completely overridden and should be reviewed if this test breaks)
    assert_checksum %w(40b18f67d953eda5041ac5c20233b784 3b6458f97969e95d304bbe25008e6dc4), "app/models/project.rb"
  end

end
