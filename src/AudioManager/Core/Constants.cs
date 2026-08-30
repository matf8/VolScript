namespace VolScript.Audio
{
    internal enum EDataFlow
    {
        Render = 0,
        Capture = 1,
        All = 2
    }

    internal enum ERole
    {
        Console = 0,
        Multimedia = 1,
        Communications = 2
    }

    internal static class CoreAudioConstants
    {
        public const float MinVolume = 0.0f;
        public const float MaxVolume = 1.0f;

        public const int ClsctxInprocServer = 0x1;
        public const int ClsctxAll = 0x17;
    }
}