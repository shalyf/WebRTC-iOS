#include "sdk/objc/native/src/audio/audio_buffer_source.h"

#include "audio/utility/audio_frame_operations.h"
#include "modules/audio_mixer/audio_mixer_impl.h"
#include "rtc_base/checks.h"
#include "rtc_base/logging.h"

namespace webrtc {

using AudioFrameInfo = AudioMixer::Source::AudioFrameInfo;

// namespace {
// // Resample audio in |frame| to given sample rate preserving the
// // channel count and place the result in |destination|.
// int Resample(const AudioFrame& frame,
//              const int destination_sample_rate,
//              PushResampler<int16_t>* resampler,
//              int16_t* destination) {
//   const int number_of_channels = static_cast<int>(frame.num_channels_);
//   const int target_number_of_samples_per_channel =
//       destination_sample_rate / 100;
//   resampler->InitializeIfNeeded(frame.sample_rate_hz_, destination_sample_rate,
//                                 number_of_channels);

//   // TODO(yujo): make resampler take an AudioFrame, and add special case
//   // handling of muted frames.
//   return resampler->Resample(
//       frame.data(), frame.samples_per_channel_ * number_of_channels,
//       destination, number_of_channels * target_number_of_samples_per_channel);
// }

// } // namespace

namespace ios_adm {

AudioBufferSource::AudioBufferSource(int ssrc, int sample_rate)
    : ssrc_(ssrc),
      sample_rate_(sample_rate),
      samples_per_channel_(sample_rate * webrtc::AudioMixerImpl::kFrameDurationInMs / 1000),
      num_samples_(0),
      num_channels_(1),
      volume_(1) {
  audio_buffer_.Clear();
}

AudioBufferSource::~AudioBufferSource() {}

void AudioBufferSource::SetSampleRate(int sample_rate) {
  sample_rate_ = sample_rate;
  samples_per_channel_ = sample_rate * webrtc::AudioMixerImpl::kFrameDurationInMs / 1000;
  RTC_DLOG(INFO) << "mixer -> SetSampleRate sample_rate: " << sample_rate_ << " samples_per_channel: " << samples_per_channel_;
}

void AudioBufferSource::SetData(const int16_t* data,
                                size_t num_samples,
                                size_t num_channels) {
  SetSamples(num_samples, num_channels);
  audio_buffer_.Clear();
  audio_buffer_.SetData(data, num_samples * num_channels);
}

void AudioBufferSource::AppendData(const int16_t* data,
                                   size_t num_samples,
                                   size_t num_channels) {
  SetSamples(num_samples, num_channels);
  audio_buffer_.AppendData(data, num_samples * num_channels);
}

rtc::ArrayView<const int16_t> AudioBufferSource::GetAudioBuffer(size_t length) {
  rtc::ArrayView<const int16_t> result;
  if (size() == length) {
    result = rtc::ArrayView<const int16_t>(audio_buffer_);
    audio_buffer_.Clear();
  } else {
    size_t num_elements = std::min(size(), length);
    result = rtc::ArrayView<const int16_t>(data(), num_elements);
    memmove(data(), data() + num_elements, (size() - num_elements) * sizeof(int16_t));
    audio_buffer_.SetSize(size() - num_elements);
  }
  return result;
}

void AudioBufferSource::SetSize(size_t num_samples, size_t num_channels) {
  SetSamples(num_samples, num_channels);
  audio_buffer_.SetSize(num_samples * num_channels);
}

void AudioBufferSource::SetSamples(size_t num_samples, size_t num_channels) {
  if (num_samples_ != num_samples || num_channels_ != num_channels) {
    num_samples_ = num_samples;
    num_channels_ = num_channels;
    RTC_DLOG(INFO) << "mixer -> SetSamples num_samples: " << num_samples << " num_channels: " << num_channels;
  }
}

void AudioBufferSource::Clear() {
  audio_buffer_.Clear();
}

void AudioBufferSource::SetMute(bool mute) {
  if (mute == muted_) return;
  muted_ = mute;
}

void AudioBufferSource::SetVolume(double volume) {
  if (volume == volume_) return;
  if (volume < 0) volume_ = 0;
  else if (volume > 1) volume_ = 1;
  else volume_ = volume;
  RTC_DLOG(INFO) << "mixer -> volume: " << volume_;
}

AudioFrameInfo AudioBufferSource::GetAudioFrameWithInfo(
    int sample_rate_hz,
    AudioFrame* audio_frame) {
  if (sample_rate_hz != sample_rate_) {
    RTC_DLOG(LERROR) << "mixer(" << ssrc_ << ") -> sample_rate_hz(" << sample_rate_hz << ") is not equal to sample_rate_(" << sample_rate_ << ")";
    return AudioFrameInfo::kError;
  }

  size_t num_elements = samples_per_channel_ * num_channels_;

  if (muted_ || size() < num_elements) {
    return AudioFrameInfo::kMuted;
  }

  // RTC_DLOG(INFO) << "mixer -> source: " << ssrc_ << " size: " << size();

  audio_frame->UpdateFrame(0, data(), samples_per_channel_, sample_rate_hz,
                           AudioFrame::SpeechType::kNormalSpeech,
                           AudioFrame::VADActivity::kVadActive,
                           num_channels_);

  memmove(data(), data() + num_elements, (size() - num_elements) * sizeof(int16_t));
  audio_buffer_.SetSize(size() - num_elements);

  // // 音量需要调节
  // if (volume_ < 0.99f) {
  //   AudioFrameOperations::ScaleWithSat(volume_, audio_frame);
  // }

  // int ret = webrtc::Resample(frame, sample_rate_hz, &resampler_, audio_frame->mutable_data());
  // RTC_DLOG(INFO) << "Resample.result: " << ret;

  // audio_frame->UpdateFrame(0, data(), ret, sample_rate_hz,
  //                          AudioFrame::SpeechType::kNormalSpeech,
  //                          AudioFrame::VADActivity::kVadActive, num_channels_);

  return AudioFrameInfo::kNormal;
}

}  // namespace ios_adm
}  // namespace webrtc