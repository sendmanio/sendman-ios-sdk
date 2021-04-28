Pod::Spec.new do |s|
  s.name             = 'SendMan'
  s.version          = '1.0.7'
  s.summary          = 'SendMan push notification management SDK for iOS apps'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage         = 'https://sendman.io'
  s.authors           = { 'SendMan' => 'support@sendman.io' }
  s.source           = { :git => 'https://github.com/sendmanio/sendman-ios-sdk.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'SendMan/Classes/**/*'
end
