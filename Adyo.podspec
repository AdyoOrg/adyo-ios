Pod::Spec.new do |s|
  s.name = 'Adyo'
  s.version = '1.0.0'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'Adyo iOS SDK'
  s.homepage = 'https://github.com/AdyoOrg/adyo-ios'
  s.authors = { 'UnitX' => 'devops@unitx.co.za' }
  s.source = { :git => 'https://github.com/AdyoOrg/adyo-ios.git', :tag => "v#{s.version}" }
  s.source_files = 'Adyo/Adyo/*'
  s.platform     = :ios, '9.0'
  s.frameworks = 'Foundation', 'UIKit', 'AdSupport', 'WebKit'
end