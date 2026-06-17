require "spec_helper"

describe "FilesChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should ensure project patch file is up to date" do
    # 6.0 / 6.1 / trunk checksums (the self.allowed_to_condition method is completely overridden and should be reviewed if this test breaks)
    assert_checksum %w(601659a9f0979d68453ec381451331ac 7a81704769de36b09964de216c26c621 885bf5f74d0ada1fc1a1736744c16667), "app/models/project.rb"
  end

end
