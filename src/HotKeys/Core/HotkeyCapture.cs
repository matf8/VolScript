using VolScript.HotKeys;
using VolScript.HotKeys.Keyboard;
using VolScript.HotKeys.Native;

namespace VolScript
{
    public static class VolScriptHotkeyCapture
    {
        private static readonly KeyboardHookListener HookListener =
            new KeyboardHookListener();

        private static bool _shiftPressed;
        private static bool _controlPressed;
        private static bool _altPressed;
        private static bool _complete;
        private static bool _keepCurrent;
        private static string _result = "";


        public static bool IsComplete
        {
            get { return _complete; }
        }


        public static bool KeepCurrent
        {
            get { return _keepCurrent; }
        }


        public static string Result
        {
            get { return _result; }
        }


        public static bool ShiftPressed
        {
            get { return _shiftPressed; }
        }


        public static bool ControlPressed
        {
            get { return _controlPressed; }
        }


        public static bool AltPressed
        {
            get { return _altPressed; }
        }


        public static void Start()
        {
            Stop();

            _shiftPressed = false;
            _controlPressed = false;
            _altPressed = false;
            _complete = false;
            _keepCurrent = false;
            _result = "";

            HookListener.Start(HandleKeyEvent);

            HookListener.WaitUntilReady();
        }


        public static void Stop()
        {
            HookListener.Stop();
        }


        public static void FlushConsoleInput()
        {
            Kernel32.FlushConsoleInputBuffer(
                Kernel32.GetStdHandle(
                    KeyboardConstants.StdInputHandle));
        }


        private static void HandleKeyEvent(
            int virtualKeyCode,
            bool isKeyDown)
        {
            if (_complete)
            {
                return;
            }

            if (HotkeyModifierHelper.IsModifierKey(
                virtualKeyCode))
            {
                HotkeyModifierHelper.UpdateModifierState(
                    virtualKeyCode,
                    isKeyDown,
                    ref _shiftPressed,
                    ref _controlPressed,
                    ref _altPressed);

                return;
            }

            if (!isKeyDown)
            {
                return;
            }

            if (virtualKeyCode == KeyboardConstants.VkReturn)
            {
                if (!_shiftPressed &&
                    !_controlPressed &&
                    !_altPressed)
                {
                    _keepCurrent = true;
                    _complete = true;
                }

                return;
            }

            string keyName =
                HotkeyNameHelper.FormatKeyName(
                    virtualKeyCode);

            if (keyName == null)
            {
                return;
            }

            _result =
                HotkeyNameHelper.BuildHotkeyString(
                    HotkeyModifierHelper.GetModifierFlags(),
                    keyName);

            _complete = true;
        }
    }
}
