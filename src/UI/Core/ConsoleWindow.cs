using VolScript.UI.Native;

namespace VolScript.UI
{
    public static class ConsoleWindow
    {
        private const int SwHide = 0;
        private const int SwShow = 5;

        public static void Hide()
        {
            User32.ShowWindow(
                Kernel32.GetConsoleWindow(),
                SwHide);
        }

        public static void Show()
        {
            User32.ShowWindow(
                Kernel32.GetConsoleWindow(),
                SwShow);
        }
    }
}
