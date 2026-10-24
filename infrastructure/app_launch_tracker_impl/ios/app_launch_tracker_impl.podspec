Pod::Spec.new do |s|
  s.name             = 'app_launch_tracker_impl'
  s.version          = '0.1.0'
  s.summary          = 'App launch tracker — native timestamp channel.'
  s.description      = <<-DESC
    Captures native launch milestones (app init, engine attach, first frame,
    splash) and the launch type via a
    platform channel. Ships in release builds; spans are consent-gated.
  DESC
  s.homepage         = 'https://archipelago.banuacoder.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Archipelago' => 'hello@banuacoder.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
