using System;
using System.Runtime.InteropServices;

namespace VolScript.UI.Native
{
    internal static class Kernel32
    {
        [DllImport("kernel32.dll")]
        internal static extern IntPtr GetConsoleWindow();
    }
}
