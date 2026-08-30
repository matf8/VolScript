using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace VolScript.Audio
{
    internal static class ComHelpers
    {
        public static void ThrowIfFailed(int hResult)
        {
            if (hResult >= 0)
            {
                return;
            }

            throw new COMException(
                new Win32Exception(hResult).Message,
                hResult);
        }
    }
}