using VolScript.HotKeys.Native;

namespace VolScript.HotKeys.Keyboard
{
    internal static class HotkeyModifierHelper
    {
        internal static bool IsModifierKey(
            int virtualKeyCode)
        {
            switch (virtualKeyCode)
            {
                case 0x10:
                case 0x11:
                case 0x12:
                case 0xA0:
                case 0xA1:
                case 0xA2:
                case 0xA3:
                case 0xA4:
                case 0xA5:
                    return true;

                default:
                    return false;
            }
        }


        internal static bool IsModifierDown(
            int virtualKey)
        {
            return (
                User32.GetAsyncKeyState(
                    virtualKey) &
                0x8000
            ) != 0;
        }


        internal static int GetModifierFlags()
        {
            int flags = 0;

            if (IsModifierDown(
                KeyboardConstants.VkShift))
            {
                flags |= KeyboardConstants.ModifierShift;
            }

            if (IsModifierDown(
                KeyboardConstants.VkControl))
            {
                flags |= KeyboardConstants.ModifierControl;
            }

            if (IsModifierDown(
                KeyboardConstants.VkMenu))
            {
                flags |= KeyboardConstants.ModifierAlt;
            }

            return flags;
        }


        internal static bool MatchesHotkey(
            int key,
            int modifierFlags,
            int virtualKeyCode)
        {
            if (virtualKeyCode != key)
            {
                return false;
            }

            if (modifierFlags == 0)
            {
                return true;
            }

            if ((modifierFlags & KeyboardConstants.ModifierShift) != 0 &&
                !IsModifierDown(KeyboardConstants.VkShift))
            {
                return false;
            }

            if ((modifierFlags & KeyboardConstants.ModifierControl) != 0 &&
                !IsModifierDown(KeyboardConstants.VkControl))
            {
                return false;
            }

            if ((modifierFlags & KeyboardConstants.ModifierAlt) != 0 &&
                !IsModifierDown(KeyboardConstants.VkMenu))
            {
                return false;
            }

            return true;
        }


        internal static void UpdateModifierState(
            int virtualKeyCode,
            bool isPressed,
            ref bool shiftPressed,
            ref bool controlPressed,
            ref bool altPressed)
        {
            switch (virtualKeyCode)
            {
                case 0x10:
                case 0xA0:
                case 0xA1:
                    shiftPressed = isPressed;

                    break;

                case 0x11:
                case 0xA2:
                case 0xA3:
                    controlPressed = isPressed;

                    break;

                case 0x12:
                case 0xA4:
                case 0xA5:
                    altPressed = isPressed;

                    break;
            }
        }
    }
}
