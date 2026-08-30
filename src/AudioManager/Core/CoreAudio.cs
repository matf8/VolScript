using System;
using System.Runtime.InteropServices;

namespace VolScript.Audio
{
    public static class CoreAudio
    {
        public static void SetProcessVolume(
            string processName,
            float volume)
        {
            processName =
                NormalizeProcessName(processName);

            if (volume < CoreAudioConstants.MinVolume ||
                volume > CoreAudioConstants.MaxVolume)
            {
                throw new ArgumentOutOfRangeException(
                    "volume");
            }

            IAudioSessionManager2 sessionManager =
                GetAudioSessionManager();

            AudioSession.SetVolume(
                sessionManager,
                processName,
                volume);
        }


        public static float GetProcessVolume(
            string processName)
        {
            processName =
                NormalizeProcessName(processName);

            IAudioSessionManager2 sessionManager =
                GetAudioSessionManager();

            return AudioSession.GetVolume(
                sessionManager,
                processName);
        }


        private static string NormalizeProcessName(
            string processName)
        {
            if (processName.EndsWith(
                ".exe",
                StringComparison.OrdinalIgnoreCase))
            {
                processName = processName.Substring(
                    0,
                    processName.Length - 4);
            }

            return processName.ToLowerInvariant();
        }


        private static IAudioSessionManager2 GetAudioSessionManager()
        {
            IMMDeviceEnumerator enumerator =
                (IMMDeviceEnumerator)new MMDeviceEnumerator();

            IMMDevice device;

            int hResult = enumerator.GetDefaultAudioEndpoint(
                (int)EDataFlow.Render,
                (int)ERole.Multimedia,
                out device);

            ComHelpers.ThrowIfFailed(hResult);

            Guid managerGuid =
                typeof(IAudioSessionManager2).GUID;

            object managerObject;

            hResult = device.Activate(
                ref managerGuid,
                CoreAudioConstants.ClsctxAll,
                IntPtr.Zero,
                out managerObject);

            ComHelpers.ThrowIfFailed(hResult);

            return (IAudioSessionManager2)managerObject;
        }
    }
}