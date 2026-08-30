using VolScript.UI.Native;

namespace VolScript.UI
{
    public static class ConsoleWindow
    {
        private const int SwHide = 0;
        private const int SwShow = 5;

        public static void Hide()
        {
            var handle = Kernel32.GetConsoleWindow();

            if (handle == IntPtr.Zero)
            {
                return;
            }

            User32.ShowWindow(handle, SwHide);
            User32.ShowWindow(handle, SwHide);
        }

        public static void Show()
        {
            User32.ShowWindow(
                Kernel32.GetConsoleWindow(),
                SwShow);
        }
    }
}
