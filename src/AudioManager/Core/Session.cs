using System;
using System.Diagnostics;

namespace VolScript.Audio
{
    internal static class AudioSession
    {
        public static void SetVolume(
            IAudioSessionManager2 sessionManager,
            string processName,
            float volume)
        {
            ISimpleAudioVolume audioVolume =
                FindByProcessName(
                    sessionManager,
                    processName);

            Guid eventContext = Guid.Empty;

            int hResult = audioVolume.SetMasterVolume(
                volume,
                ref eventContext);

            ComHelpers.ThrowIfFailed(hResult);
        }


        public static float GetVolume(
            IAudioSessionManager2 sessionManager,
            string processName)
        {
            ISimpleAudioVolume audioVolume =
                FindByProcessName(
                    sessionManager,
                    processName);

            float volume;

            int hResult = audioVolume.GetMasterVolume(
                out volume);

            ComHelpers.ThrowIfFailed(hResult);

            return volume;
        }


        private static ISimpleAudioVolume FindByProcessName(
            IAudioSessionManager2 sessionManager,
            string processName)
        {
            IAudioSessionEnumerator sessions;

            int hResult = sessionManager.GetSessionEnumerator(
                out sessions);

            ComHelpers.ThrowIfFailed(hResult);

            int count;

            hResult = sessions.GetCount(
                out count);

            ComHelpers.ThrowIfFailed(hResult);

            for (int i = 0; i < count; i++)
            {
                IAudioSessionControl2 session;

                hResult = sessions.GetSession(
                    i,
                    out session);

                if (hResult < 0)
                {
                    continue;
                }

                uint processId;

                hResult = session.GetProcessId(
                    out processId);

                if (hResult < 0 || processId == 0)
                {
                    continue;
                }

                Process process;

                try
                {
                    process = Process.GetProcessById(
                        (int)processId);
                }
                catch
                {
                    continue;
                }

                if (!string.Equals(
                    process.ProcessName,
                    processName,
                    StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                try
                {
                    return (ISimpleAudioVolume)session;
                }
                catch (InvalidCastException)
                {
                    continue;
                }
            }

            throw new InvalidOperationException(
                "No audio session found for " +
                processName +
                ".exe");
        }
    }
}
