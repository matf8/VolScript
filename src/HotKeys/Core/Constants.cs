namespace VolScript.HotKeys
{
    internal static class KeyboardConstants
    {
        internal const int WhKeyboardLl = 13;

        internal const int WmKeyDown = 0x0100;
        internal const int WmKeyUp = 0x0101;
        internal const int WmSysKeyDown = 0x0104;
        internal const int WmSysKeyUp = 0x0105;
        internal const int WmQuit = 0x0012;

        internal const int VkShift = 0x10;
        internal const int VkControl = 0x11;
        internal const int VkMenu = 0x12;
        internal const int VkReturn = 0x0D;
        internal const int VkEscape = 0x1B;

        internal const int ModifierShift = 1;
        internal const int ModifierControl = 2;
        internal const int ModifierAlt = 4;

        internal const int StdInputHandle = -10;
    }
}
