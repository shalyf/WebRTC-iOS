/*
 *  Copyright (c) 2020 Easher. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef SDK_OBJC_NATIVE_SRC_AUDIO_BUFFER_SOURCE_H_
#define SDK_OBJC_NATIVE_SRC_AUDIO_BUFFER_SOURCE_H_

#include <memory>

#include "api/audio/audio_frame.h"
#include "api/audio/audio_mixer.h"
#include "common_audio/resampler/include/push_resampler.h"
#include "rtc_base/buffer.h"

namespace webrtc {

namespace ios_adm {

class AudioBufferSource : public AudioMixer::Source {
 public:
  AudioBufferSource(int ssrc, int sample_rate);
  ~AudioBufferSource() override;

  void SetSampleRate(int sample_rate);

  void SetData(const int16_t* data, size_t num_samples, size_t num_channels);

  void AppendData(const int16_t* data, size_t num_samples, size_t num_channels);

  rtc::ArrayView<const int16_t> GetAudioBuffer(size_t length);

  void SetSize(size_t num_samples, size_t num_channels);

  void SetSamples(size_t num_samples, size_t num_channels);

  void Clear();

  void SetMute(bool mute);

  void SetVolume(double volume);

  AudioFrameInfo GetAudioFrameWithInfo(int sample_rate_hz,
                                       AudioFrame* audio_frame) override;

  int Ssrc() const override { return ssrc_; }

  int PreferredSampleRate() const override { return sample_rate_; }

  int16_t* data() { return audio_buffer_.data(); }

  size_t size() const { return audio_buffer_.size(); }

  bool empty() const { return audio_buffer_.empty(); }

  size_t num_samples() { return num_samples_; }

  size_t num_channels() { return num_channels_; }

  bool muted() const { return muted_; }

  rtc::ArrayView<const int16_t> audio_buffer() { return audio_buffer_; }

 private:
  int ssrc_;
  int sample_rate_;
  int samples_per_channel_;
  size_t num_samples_;
  size_t num_channels_;
  double volume_;
  bool muted_;
  rtc::BufferT<int16_t> audio_buffer_;

  // Converts mixed audio to the audio device output rate.
  PushResampler<int16_t> resampler_;
};

}  // namespace ios_adm
}  // namespace webrtc

#endif  // SDK_OBJC_NATIVE_SRC_AUDIO_BUFFER_SOURCE_H_
