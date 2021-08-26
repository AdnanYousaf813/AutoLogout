Pod::Spec.new do |spec|

  spec.name         = "AutoLogout"
  spec.version      = "1.0.0"
  spec.summary      = "A Library for Auto Expire Session"
  spec.description  = "On user inactivity session will expire automatically after the time you will set"
  spec.homepage     = "https://github.com/AdnanYousaf813/AutoLogout"
  spec.license      = "MIT"
  spec.author       = { "Adnan Yousaf" => "adnanyousaf813@gmail.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/AdnanYousaf813/AutoLogout.git", :tag => "1.0.0" }
  spec.source_files  = "AutoLogout", "AutoLogout/**/*.{h,m,swift,xib}"
  spec.swift_versions = "5.3"

end
