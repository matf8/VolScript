using System;
using System.Runtime.InteropServices;

namespace VolScript.UI.Native
{
    internal static class User32
    {
        [DllImport("user32.dll")]
        internal static extern bool ShowWindow(
            IntPtr windowHandle,
            int command);
    }
}
