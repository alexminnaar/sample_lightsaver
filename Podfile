# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'LightSaver' do
  use_frameworks!

  # Pods for ARKitInteraction
  pod 'MapsyncLib', :podspec => './MapsyncLib.podspec'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    plist_buddy = "/usr/libexec/PlistBuddy"
    plist = "Pods/Target Support Files/#{target}/Info.plist"
    `#{plist_buddy} -c "Add UIRequiredDeviceCapabilities array" "#{plist}"`
    `#{plist_buddy} -c "Add UIRequiredDeviceCapabilities:0 string arm64" "#{plist}"`
  end
end

end
