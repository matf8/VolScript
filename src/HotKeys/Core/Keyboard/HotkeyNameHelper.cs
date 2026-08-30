using System.Text;

namespace VolScript.HotKeys.Keyboard
{
    internal static class HotkeyNameHelper
    {
        internal static string FormatKeyName(
            int virtualKeyCode)
        {
            if (
                virtualKeyCode >= 0x41 &&
                virtualKeyCode <= 0x5A)
            {
                return (
                    (char)virtualKeyCode
                ).ToString();
            }

            if (
                virtualKeyCode >= 0x30 &&
                virtualKeyCode <= 0x39)
            {
                return (
                    (char)virtualKeyCode
                ).ToString();
            }

            if (
                virtualKeyCode >= 0x70 &&
                virtualKeyCode <= 0x7B)
            {
                return "F" + (
                    virtualKeyCode - 0x70 + 1);
            }

            if (virtualKeyCode == KeyboardConstants.VkEscape)
            {
                return "ESC";
            }

            return null;
        }


        internal static string BuildHotkeyString(
            int modifierFlags,
            string keyName)
        {
            StringBuilder builder =
                new StringBuilder();

            if ((modifierFlags & KeyboardConstants.ModifierControl) != 0)
            {
                AppendPart(builder, "CTRL");
            }

            if ((modifierFlags & KeyboardConstants.ModifierAlt) != 0)
            {
                AppendPart(builder, "ALT");
            }

            if ((modifierFlags & KeyboardConstants.ModifierShift) != 0)
            {
                AppendPart(builder, "SHIFT");
            }

            AppendPart(builder, keyName);

            return builder.ToString();
        }


        private static void AppendPart(
            StringBuilder builder,
            string part)
        {
            if (builder.Length > 0)
            {
                builder.Append("+");
            }

            builder.Append(part);
        }
    }
}
