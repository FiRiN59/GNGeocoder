Pod::Spec.new do |s|
  s.name         = "GNGeocoder"
  s.version      = "0.0.4"
  s.summary      = "Library wrapper for using Google Geocoding API"

  s.description  = <<-DESC
                   Library wrapper for using Google Geocoding API.
                   DESC

  s.homepage     = "https://github.com/jakubknejzlik/GNGeocoder"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Jakub Knejzlik" => "jakub.knejzlik@gmail.com" }

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"

  s.source       = { :git => "https://github.com/FiRiN59/GNGeocoder.git", :tag => s.version.to_s }

  s.source_files  = "GNGeocoder", "GNGeocoder/**/*.{h,m}"

  s.frameworks = "CoreLocation", "MapKit"
  
  s.requires_arc = true

  s.dependency "AFNetworking"

end
