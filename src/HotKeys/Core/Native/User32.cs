using System;
using System.Runtime.InteropServices;

namespace VolScript.HotKeys.Native
{
    internal delegate IntPtr LowLevelKeyboardProc(
        int nCode,
        IntPtr wParam,
        IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    internal struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pointX;
        public int pointY;
    }

    internal static class User32
    {
        [DllImport("user32.dll")]
        internal static extern IntPtr SetWindowsHookEx(
            int idHook,
            LowLevelKeyboardProc callback,
            IntPtr moduleHandle,
            uint threadId);

        [DllImport("user32.dll")]
        internal static extern bool UnhookWindowsHookEx(
            IntPtr hook);

        [DllImport("user32.dll")]
        internal static extern IntPtr CallNextHookEx(
            IntPtr hook,
            int nCode,
            IntPtr wParam,
            IntPtr lParam);

        [DllImport("user32.dll")]
        internal static extern bool PostThreadMessage(
            uint threadId,
            uint message,
            IntPtr wParam,
            IntPtr lParam);

        [DllImport("user32.dll")]
        internal static extern short GetAsyncKeyState(
            int virtualKey);

        [DllImport("user32.dll")]
        internal static extern bool PeekMessage(
            out MSG message,
            IntPtr windowHandle,
            uint minimumMessage,
            uint maximumMessage,
            uint removeMessage);

        [DllImport("user32.dll")]
        internal static extern int GetMessage(
            out MSG message,
            IntPtr windowHandle,
            uint minimumMessage,
            uint maximumMessage);

        [DllImport("user32.dll")]
        internal static extern bool TranslateMessage(
            ref MSG message);

        [DllImport("user32.dll")]
        internal static extern IntPtr DispatchMessage(
            ref MSG message);
    }
}
