Pod::Spec.new do |s|
  s.name         = "JidoMaps"
  s.version      = "0.2.6"
  s.summary      = "A short description of JidoMaps."

  s.description  = <<-DESC
  beta test pod.  
                   DESC

  s.homepage     = "http://mapsync.io"
  s.license      = "MIT"
  s.author       = { "Jaeyong Sung" => "jae@mapsync.io" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => 'https://github.com/jidomaps/jido_pods.git', :tag => 'v0.2.6' }
  s.ios.deployment_target = '11.0'
  s.ios.vendored_frameworks = 'JidoMaps.framework'
  s.exclude_files = "Classes/Exclude"

  s.dependency "AWSS3", "~> 2.6.10"
  s.dependency "Alamofire", "~> 4.6.0"
  s.dependency "SwiftyJSON", "~> 4.0.0"
  s.dependency "SwiftHash"
  s.dependency "AWSCloudWatch"
  s.dependency "AWSDynamoDB"

end