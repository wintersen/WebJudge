require 'zip'

tempfile = "testwebsite.zip"

Zip::File.open(tempfile) do |zip_file|
  zip_file.each do |f|
    fpath = File.join("websites\\", f.name)
    zip_file.extract(f, fpath) unless File.exist?(fpath)
  end
end