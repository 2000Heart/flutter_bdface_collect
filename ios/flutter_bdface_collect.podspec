#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_bdface_collect.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_bdface_collect'
  s.version          = '0.0.1'
  s.summary          = 'a baidu face collect plugin. Only Android and IOS platforms are supported.'
  s.description      = <<-DESC
a baidu face collect plugin. Only Android and IOS platforms are supported.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.static_framework = true
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  # 官方整包：IDLFaceSDK（算法）+ BDFaceBaseKit（UI/流程），以及语音/图片/模型 bundle 与参数配置
  # local_config.json 由宿主 App 自行放入 Runner/Copy Bundle Resources，勿在此打包，否则会与 App 资源冲突
  s.resources = [
    'BDFaceSDK/*.bundle',
    'BDFaceSDK/BDFaceParamsConfig.json'
  ]
  s.resource_bundles = {
    'flutter_bdface_collect_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
  s.vendored_frameworks = 'BDFaceSDK/*.framework'
  s.libraries = ['c++']
  s.frameworks = ['AVFoundation', 'CoreMedia', 'CoreVideo', 'AudioToolbox', 'CoreTelephony', 'SystemConfiguration', 'Accelerate']
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice. New IDLFaceSDK is arm64-only.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'OTHER_LDFLAGS' => '-ObjC',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'OTHER_LDFLAGS' => '-ObjC'
  }
end
