#ifndef SDK_OBJC_NATIVE_SRC_AUDIO_FILE_RECORDER_H_
#define SDK_OBJC_NATIVE_SRC_AUDIO_FILE_RECORDER_H_

#include <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#include <Foundation/Foundation.h>
#include <iostream>
#include "rtc_base/synchronization/mutex.h"

namespace webrtc {

class AudioFileRecorder {
 public:
  AudioFileRecorder(std::string destinationPath,
                    AudioFormatID destinationFormatID_,
                    double sampleRate,
                    size_t channels);
  ~AudioFileRecorder();

  void StartRecording();
  void StopRecording();
  void AppendAudioBufferList(const AudioBufferList *abl, UInt32 numberOfFrames);
  bool IsRunning();

 private:
  NSString *destinationPath_;
  AudioFormatID destinationFormatID_;
  ExtAudioFileRef destinationFile_ RTC_GUARDED_BY(recording_mutex_);
  double sampleRate_;
  size_t channels_;
  bool running_;

  webrtc::Mutex recording_mutex_;
};

}

#endif  // SDK_OBJC_NATIVE_SRC_AUDIO_FILE_RECORDER_H_
