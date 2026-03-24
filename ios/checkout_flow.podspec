Pod::Spec.new do |s|
  s.name             = 'checkout_flow'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin for Checkout.com Flow payment components.'
  s.description      = 'Integrates Checkout.com Flow for accepting payments on iOS and Android.'
  s.homepage         = 'https://checkout.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Community' => '' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'CheckoutComponentsSDK'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
end
