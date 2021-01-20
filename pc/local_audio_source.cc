/*
 *  Copyright 2013 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "pc/local_audio_source.h"
#include "rtc_base/logging.h"
#include "rtc_base/ref_counted_object.h"

using webrtc::MediaSourceInterface;

namespace webrtc {

rtc::scoped_refptr<LocalAudioSource> LocalAudioSource::Create(
    AudioDeviceModule* adm,
    const cricket::AudioOptions* audio_options) {
  rtc::scoped_refptr<LocalAudioSource> source(
      new rtc::RefCountedObject<LocalAudioSource>());
  source->Initialize(adm, audio_options);
  RTC_LOG(INFO) << __FUNCTION__;
  return source;
}

void LocalAudioSource::Initialize(
  AudioDeviceModule* adm,
  const cricket::AudioOptions* audio_options) {
  if (!audio_options)
    return;
  audioDeviceModule_ = adm;
  options_ = *audio_options;
}

void LocalAudioSource::CaptureData(const int16_t* audio_data, size_t* params) {
  audioDeviceModule_->CaptureData(audio_data, params);
}

}  // namespace webrtc
