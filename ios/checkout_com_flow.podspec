Pod::Spec.new do |s|
  s.name             = 'checkout_com_flow'
  s.version          = '0.3.0'
  s.summary          = 'Flutter plugin for Checkout.com Flow payment components.'
  s.description      = 'Integrates Checkout.com Flow for accepting payments on iOS and Android.'
  s.homepage         = 'https://github.com/lbdsh/checkout_flutter_plugin'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'lbdsh.com' => 'antonino@lbdsh.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'checkout_com_flow/Sources/checkout_com_flow/**/*'
  s.dependency 'Flutter'
  s.vendored_frameworks = 'CheckoutComponentsSDK.xcframework'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
  }
end
