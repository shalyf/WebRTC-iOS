#import "audio_file_recorder.h"

#import "base/RTCLogging.h"

namespace webrtc {

AudioFileRecorder::AudioFileRecorder(std::string destinationPath,
                                     AudioFormatID destinationFormatID,
                                     double sampleRate,
                                     size_t channels)
    : destinationPath_([NSString stringWithCString:destinationPath.c_str()
                                          encoding:[NSString defaultCStringEncoding]]),
      destinationFormatID_(destinationFormatID),
      destinationFile_(0),
      sampleRate_(sampleRate),
      channels_(channels),
      running_(false) {
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:destinationPath_]) {
    [fm removeItemAtPath:destinationPath_ error:nil];
  }
}

AudioFileRecorder::~AudioFileRecorder() {}

void AudioFileRecorder::StartRecording() {
  webrtc::MutexLock lock(&recording_mutex_);

  AudioStreamBasicDescription asbd = {};
  asbd.mSampleRate = sampleRate_;
  asbd.mFormatID = destinationFormatID_;
  asbd.mChannelsPerFrame = channels_;

  OSStatus result = noErr;

  // Use AudioFormat API to fill out the rest of the description.
  UInt32 size = sizeof(asbd);
  result = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &asbd);
  if (result != noErr) {
    RTCLog(@"AudioFormatGetProperty couldn't fill out the destination data format. Error=%ld.",
           (long)result);
    return;
  }

  // Create the destination audio file
  result = ExtAudioFileCreateWithURL(
      (__bridge CFURLRef _Nonnull)[NSURL fileURLWithPath:destinationPath_],
      kAudioFileAAC_ADTSType,
      &asbd,
      NULL,
      kAudioFileFlags_EraseFile,
      &destinationFile_);
  if (result != noErr) {
    RTCLog(@"ExtAudioFileCreateWithURL failed!");
    return;
  }

  /*
   set the client format - The format must be linear PCM (kAudioFormatLinearPCM)
   You must set this in order to encode or decode a non-PCM file data format
   You may set this on PCM files to specify the data format used in your calls to read/write
   */
  AudioStreamBasicDescription clientFormat;
  clientFormat.mFormatID = kAudioFormatLinearPCM;
  UInt32 sampleSize = sizeof(SInt16);
  clientFormat.mFormatFlags =
      kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
  clientFormat.mBitsPerChannel = 8 * sampleSize;
  clientFormat.mChannelsPerFrame = channels_;
  clientFormat.mFramesPerPacket = 1;
  clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame = channels_ * sampleSize;
  clientFormat.mSampleRate = sampleRate_;

  size = sizeof(clientFormat);
  result = ExtAudioFileSetProperty(
      destinationFile_, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
  if (result != noErr) {
    RTCLog(@"Couldn't set the client format on the destination file!");
    return;
  }

  running_ = true;
}

void AudioFileRecorder::StopRecording() {
  webrtc::MutexLock lock(&recording_mutex_);
  if (destinationFile_) ExtAudioFileDispose(destinationFile_);
  running_ = false;
}

void AudioFileRecorder::AppendAudioBufferList(const AudioBufferList *abl, UInt32 numberOfFrames) {
  webrtc::MutexLock lock(&recording_mutex_);
  if (!running_ || !destinationFile_) return;
  OSStatus result = ExtAudioFileWrite(destinationFile_, numberOfFrames, abl);
  if (result != noErr) RTCLog(@"ExtAudioFileWrite failed!");
}

bool AudioFileRecorder::IsRunning() {
  return running_;
}

}
