require "spec_helper"

describe "FilesChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "ensures the project patch file is up to date" do
    # 6.1.4 / 7.0.1 / trunk checksums (the self.allowed_to_condition method is completely overridden and should be reviewed if this test breaks)
    assert_checksum %w(8f1b3c7ec0cc28c13924fb626dc6257d b371ef44053677bba9c927cf47426ec1), "app/models/project.rb"
  end

end
