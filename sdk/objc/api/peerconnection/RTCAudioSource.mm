/*
 *  Copyright 2016 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "RTCAudioSource+Private.h"

#include "rtc_base/checks.h"

@implementation RTC_OBJC_TYPE (RTCAudioSource) {
}

@synthesize volume = _volume;
@synthesize nativeAudioSource = _nativeAudioSource;

- (instancetype)initWithFactory:(RTC_OBJC_TYPE(RTCPeerConnectionFactory) *)factory
              nativeAudioSource:
                  (rtc::scoped_refptr<webrtc::AudioSourceInterface>)nativeAudioSource {
  RTC_DCHECK(factory);
  RTC_DCHECK(nativeAudioSource);

  if (self = [super initWithFactory:factory
                  nativeMediaSource:nativeAudioSource
                               type:RTCMediaSourceTypeAudio]) {
    _nativeAudioSource = nativeAudioSource;
  }
  return self;
}

- (instancetype)initWithFactory:(RTC_OBJC_TYPE(RTCPeerConnectionFactory) *)factory
              nativeMediaSource:(rtc::scoped_refptr<webrtc::MediaSourceInterface>)nativeMediaSource
                           type:(RTCMediaSourceType)type {
  RTC_NOTREACHED();
  return nil;
}

- (NSString *)description {
  NSString *stateString = [[self class] stringForState:self.state];
  return [NSString stringWithFormat:@"RTC_OBJC_TYPE(RTCAudioSource)( %p ): %@", self, stateString];
}

- (void)setVolume:(double)volume {
  _volume = volume;
  _nativeAudioSource->SetVolume(volume);
}

- (void)captureData:(NSData *)data
     withNumSamples:(int)numSamples
        numChannels:(int)numChannels
             volume:(double)volume {
  const int16_t *newBytes = static_cast<const int16_t *>([data bytes]);
  size_t params[] = {static_cast<size_t>(numSamples),
                     static_cast<size_t>(numChannels),
                     static_cast<size_t>(volume * 100)};
  _nativeAudioSource->CaptureData(newBytes, params);
}

@end
