using System;
using VolScript.UI.Native;

namespace VolScript.UI
{
    public static class NativeIcons
    {
        public static void DestroyIcon(IntPtr iconHandle)
        {
            if (iconHandle == IntPtr.Zero)
            {
                return;
            }

            User32.DestroyIcon(iconHandle);
        }
    }
}
