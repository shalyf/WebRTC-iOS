

# build_ios_debug.sh
# Usage example: ./build_ios_debug.sh
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

tools_webrtc/ios/build_ios_libs.sh --arch arm64 --output-dir out_ios_debug

rm -rf /Users/yii/Documents/Projects/RemoteSupport/WebRTCKit/Frameworks/WebRTC.framework 

cp -rf /Users/yii/Documents/webrtc/webrtc/src/out_ios_debug/WebRTC.framework /Users/yii/Documents/Projects/RemoteSupport/WebRTCKit/Frameworks/
