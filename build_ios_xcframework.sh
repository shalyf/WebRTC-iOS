# build_ios_xcframework.sh
# Usage example: ./build_ios_xcframework.sh
# set -euo pipefail
# xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
# trap 'rm -f "$xcconfig"' INT TERM HUP EXIT
# # For Xcode 12 make sure EXCLUDED_ARCHS is set to arm architectures otherwise
# # the build will fail on lipo due to duplicate architectures.
# CURRENT_XCODE_VERSION=$(xcodebuild -version | grep "Build version" | cut -d' ' -f3)
# echo "EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$CURRENT_XCODE_VERSION = arm64 arm64e armv7 armv7s armv6 armv8" >> $xcconfig
# echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$(XCODE_PRODUCT_BUILD_VERSION))' >> $xcconfig
# echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> $xcconfig
# export XCODE_XCCONFIG_FILE="$xcconfig"

echo "Build webrtc"
tools_webrtc/ios/build_ios_libs.sh --output-dir out_ios_libs

ret=$?
if [[ $ret != 0 ]]; then
  echo "Build failed."
  exit $ret
fi

cd out_ios_libs

echo "Hack arm64 framework from device to work on arm64 simulator"
rm -rf arm64_simulator_libs
mkdir arm64_simulator_libs
cp -rf arm64_libs/WebRTC.framework arm64_simulator_libs
lipo -thin arm64 arm64_simulator_libs/WebRTC.framework/WebRTC -output arm64_simulator_libs/WebRTC.framework/WebRTC.arm64
../arm64-to-sim arm64_simulator_libs/WebRTC.framework/WebRTC.arm64
mv -f arm64_simulator_libs/WebRTC.framework/WebRTC.arm64 arm64_simulator_libs/WebRTC.framework/WebRTC

echo "Merge simulator binarys"
rm -rf simulator_libs
mkdir simulator_libs
cp -rf x64_libs/WebRTC.framework simulator_libs
rm simulator_libs/WebRTC.framework/WebRTC
lipo -create \
  arm64_simulator_libs/WebRTC.framework/WebRTC \
  x64_libs/WebRTC.framework/WebRTC \
  x86_libs/WebRTC.framework/WebRTC \
  -output simulator_libs/WebRTC.framework/WebRTC

echo "Merge ios binarys"
rm -rf device_libs
mkdir device_libs
cp -rf arm64_libs/WebRTC.framework device_libs
rm device_libs/WebRTC.framework/WebRTC
lipo -create \
  arm64_libs/WebRTC.framework/WebRTC \
  arm_libs/WebRTC.framework/WebRTC \
  -output device_libs/WebRTC.framework/WebRTC

echo "Create xcframework"
rm -rf WebRTC.xcframework
xcodebuild -create-xcframework \
	-framework simulator_libs/WebRTC.framework \
	-framework device_libs/WebRTC.framework \
	-output WebRTC.xcframework

# remove temporary dirs
rm -rf arm64_simulator_libs
rm -rf simulator_libs
rm -rf device_libs

echo "Done!"