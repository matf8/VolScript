using System;
using System.Runtime.InteropServices;

namespace VolScript.Audio
{
    [ComImport]
    [Guid(CoreAudioGuids.IMMDeviceEnumerator)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(
            int dataFlow,
            int stateMask,
            out IntPtr devices);

        int GetDefaultAudioEndpoint(
            int dataFlow,
            int role,
            out IMMDevice endpoint);

        int GetDevice(
            string id,
            out IMMDevice device);

        int RegisterEndpointNotificationCallback(
            IntPtr client);

        int UnregisterEndpointNotificationCallback(
            IntPtr client);
    }


    [ComImport]
    [Guid(CoreAudioGuids.IMMDevice)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice
    {
        int Activate(
            ref Guid iid,
            int clsCtx,
            IntPtr activationParams,
            [MarshalAs(UnmanagedType.Interface)]
            out object interfacePointer);

        int OpenPropertyStore(
            int access,
            out IntPtr properties);

        int GetId(
            out string id);

        int GetState(
            out int state);
    }


    [ComImport]
    [Guid(CoreAudioGuids.IAudioSessionManager2)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionManager2
    {
        int NotImpl1();

        int NotImpl2();

        int GetSessionEnumerator(
            out IAudioSessionEnumerator sessionEnum);
    }


    [ComImport]
    [Guid(CoreAudioGuids.IAudioSessionEnumerator)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionEnumerator
    {
        int GetCount(
            out int count);

        int GetSession(
            int index,
            out IAudioSessionControl2 session);
    }


    [ComImport]
    [Guid(CoreAudioGuids.IAudioSessionControl2)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionControl2
    {
        int GetState(
            out int state);

        int GetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string name);

        int SetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            string name,
            ref Guid eventContext);

        int GetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string path);

        int SetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            string path,
            ref Guid eventContext);

        int GetGroupingParam(
            out Guid groupingId);

        int SetGroupingParam(
            ref Guid groupingId,
            ref Guid eventContext);

        int RegisterAudioSessionNotification(
            IntPtr client);

        int UnregisterAudioSessionNotification(
            IntPtr client);

        int GetSessionIdentifier(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string id);

        int GetSessionInstanceIdentifier(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string id);

        int GetProcessId(
            out uint processId);

        int IsSystemSoundsSession();

        int SetDuckingPreference(
            bool optOut);
    }


    [ComImport]
    [Guid(CoreAudioGuids.ISimpleAudioVolume)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISimpleAudioVolume
    {
        int SetMasterVolume(
            float level,
            ref Guid eventContext);

        int GetMasterVolume(
            out float level);

        int SetMute(
            bool mute,
            ref Guid eventContext);

        int GetMute(
            out bool mute);
    }
}