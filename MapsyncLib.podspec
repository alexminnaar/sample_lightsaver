Pod::Spec.new do |s|  
    s.name              = 'MapsyncLib'
    s.version           = '0.1.6'
    s.summary           = 'A simple API for persistent augmented reality.'
    s.homepage          = 'http://mapsync.io/'

    s.author            = { 'Mapsync' => 'mark@jidomaps.com' }
    s.license           = { :type => 'Apache-2.0', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :git => 'https://github.com/jidomaps/jido_pods.git', :tag => 'v0.1.6' }

    s.ios.deployment_target = '11.0'
    s.ios.vendored_frameworks = 'MapsyncLib.framework'

	s.dependency "AWSS3", "~> 2.6.10"
    s.dependency "Alamofire", "~> 4.6.0"
    s.dependency "SwiftyJSON", "~> 4.0.0"
    s.dependency "SwiftHash"
end
