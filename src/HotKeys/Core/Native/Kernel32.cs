using System;
using System.Runtime.InteropServices;

namespace VolScript.HotKeys.Native
{
    internal static class Kernel32
    {
        [DllImport("kernel32.dll")]
        internal static extern IntPtr GetModuleHandle(
            string moduleName);

        [DllImport("kernel32.dll")]
        internal static extern uint GetCurrentThreadId();

        [DllImport("kernel32.dll")]
        internal static extern IntPtr GetStdHandle(
            int nStdHandle);

        [DllImport("kernel32.dll")]
        internal static extern bool FlushConsoleInputBuffer(
            IntPtr hConsoleInput);
    }
}
