Pod::Spec.new do |s|
  s.name         = "wallabee-api-ios"
  s.version      = "0.0.2"
  s.summary      = "Objective-C API for Wallabee Web Interface"
  s.homepage     = "https://github.com/BadPirate/wallabee-api-ios"
  s.license      = 'MIT'
  s.author       = { "Objective-C" => "Kevin Lohman" }
  s.source       = { :git => "https://github.com/BadPirate/wallabee-api-ios.git", :tag => s.version.to_s }

  s.platform     = :ios, '5.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  # s.resources = 'Assets'

  s.public_header_files = 'Classes/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end
