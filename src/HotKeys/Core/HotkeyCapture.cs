using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace VolScript
{
    public static class VolScriptHotkeyCapture
    {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_KEYUP = 0x0101;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const int WM_SYSKEYUP = 0x0105;
        private const int WM_QUIT = 0x0012;

        private const int VK_SHIFT = 0x10;
        private const int VK_CONTROL = 0x11;
        private const int VK_MENU = 0x12;
        private const int VK_RETURN = 0x0D;

        private const int ModifierShift = 1;
        private const int ModifierControl = 2;
        private const int ModifierAlt = 4;

        private static IntPtr _hook = IntPtr.Zero;

        private static LowLevelKeyboardProc _proc =
            HookCallback;

        private static Thread _listenerThread;

        private static uint _listenerThreadId;

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

            _listenerThread =
                new Thread(Listen);

            _listenerThread.IsBackground = true;

            _listenerThread.Start();

            while (_listenerThreadId == 0)
            {
                Thread.Sleep(10);
            }
        }


        public static void Stop()
        {
            uint threadId =
                _listenerThreadId;

            if (threadId == 0)
            {
                return;
            }

            PostThreadMessage(
                threadId,
                WM_QUIT,
                IntPtr.Zero,
                IntPtr.Zero);

            if (
                _listenerThread != null &&
                _listenerThread.IsAlive)
            {
                _listenerThread.Join(1000);
            }

            _listenerThread = null;
            _listenerThreadId = 0;
        }


        public static void FlushConsoleInput()
        {
            FlushConsoleInputBuffer(
                GetStdHandle(
                    STD_INPUT_HANDLE));
        }


        private const int STD_INPUT_HANDLE = -10;


        private static void Listen()
        {
            _listenerThreadId =
                GetCurrentThreadId();

            MSG message;

            PeekMessage(
                out message,
                IntPtr.Zero,
                0,
                0,
                0);

            using (Process process =
                Process.GetCurrentProcess())
            using (ProcessModule module =
                process.MainModule)
            {
                _hook = SetWindowsHookEx(
                    WH_KEYBOARD_LL,
                    _proc,
                    GetModuleHandle(
                        module.ModuleName),
                    0);
            }

            if (_hook == IntPtr.Zero)
            {
                _listenerThreadId = 0;

                _complete = true;

                return;
            }

            while (
                GetMessage(
                    out message,
                    IntPtr.Zero,
                    0,
                    0) > 0)
            {
                TranslateMessage(
                    ref message);

                DispatchMessage(
                    ref message);
            }

            Unhook();

            _listenerThreadId = 0;
        }


        private static void Unhook()
        {
            if (_hook == IntPtr.Zero)
            {
                return;
            }

            UnhookWindowsHookEx(
                _hook);

            _hook = IntPtr.Zero;
        }


        private static IntPtr HookCallback(
            int nCode,
            IntPtr wParam,
            IntPtr lParam)
        {
            if (nCode >= 0)
            {
                int message =
                    wParam.ToInt32();

                int virtualKeyCode =
                    Marshal.ReadInt32(
                        lParam);

                if (
                    message == WM_KEYDOWN ||
                    message == WM_SYSKEYDOWN)
                {
                    HandleKeyDown(
                        virtualKeyCode);
                }
                else if (
                    message == WM_KEYUP ||
                    message == WM_SYSKEYUP)
                {
                    HandleKeyUp(
                        virtualKeyCode);
                }
            }

            return CallNextHookEx(
                _hook,
                nCode,
                wParam,
                lParam);
        }


        private static void HandleKeyDown(
            int virtualKeyCode)
        {
            if (_complete)
            {
                return;
            }

            if (IsModifierKey(
                virtualKeyCode))
            {
                UpdateModifierState(
                    virtualKeyCode,
                    true);

                return;
            }

            if (virtualKeyCode == VK_RETURN)
            {
                if (!HasAnyModifierPressed())
                {
                    _keepCurrent = true;

                    _complete = true;
                }

                return;
            }

            string keyName =
                FormatKeyName(
                    virtualKeyCode);

            if (keyName == null)
            {
                return;
            }

            _result =
                BuildHotkeyString(
                    GetModifierFlags(),
                    keyName);

            _complete = true;
        }


        private static void HandleKeyUp(
            int virtualKeyCode)
        {
            if (_complete)
            {
                return;
            }

            if (IsModifierKey(
                virtualKeyCode))
            {
                UpdateModifierState(
                    virtualKeyCode,
                    false);
            }
        }


        private static bool HasAnyModifierPressed()
        {
            return
                _shiftPressed ||
                _controlPressed ||
                _altPressed;
        }


        private static int GetModifierFlags()
        {
            int flags = 0;

            if (IsModifierDown(VK_SHIFT))
            {
                flags |= ModifierShift;
            }

            if (IsModifierDown(VK_CONTROL))
            {
                flags |= ModifierControl;
            }

            if (IsModifierDown(VK_MENU))
            {
                flags |= ModifierAlt;
            }

            return flags;
        }


        private static string BuildHotkeyString(
            int modifierFlags,
            string keyName)
        {
            StringBuilder builder =
                new StringBuilder();

            if ((modifierFlags & ModifierControl) != 0)
            {
                AppendPart(
                    builder,
                    "CTRL");
            }

            if ((modifierFlags & ModifierAlt) != 0)
            {
                AppendPart(
                    builder,
                    "ALT");
            }

            if ((modifierFlags & ModifierShift) != 0)
            {
                AppendPart(
                    builder,
                    "SHIFT");
            }

            AppendPart(
                builder,
                keyName);

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


        private static bool IsModifierKey(
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


        private static void UpdateModifierState(
            int virtualKeyCode,
            bool isPressed)
        {
            switch (virtualKeyCode)
            {
                case 0x10:
                case 0xA0:
                case 0xA1:
                    _shiftPressed = isPressed;

                    break;

                case 0x11:
                case 0xA2:
                case 0xA3:
                    _controlPressed = isPressed;

                    break;

                case 0x12:
                case 0xA4:
                case 0xA5:
                    _altPressed = isPressed;

                    break;
            }
        }


        private static bool IsModifierDown(
            int virtualKey)
        {
            return (
                GetAsyncKeyState(
                    virtualKey) &
                0x8000
            ) != 0;
        }


        private static string FormatKeyName(
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

            if (virtualKeyCode == 0x1B)
            {
                return "ESC";
            }

            return null;
        }


        private delegate IntPtr LowLevelKeyboardProc(
            int nCode,
            IntPtr wParam,
            IntPtr lParam);


        [DllImport("user32.dll")]
        private static extern IntPtr SetWindowsHookEx(
            int idHook,
            LowLevelKeyboardProc callback,
            IntPtr moduleHandle,
            uint threadId);


        [DllImport("user32.dll")]
        private static extern bool UnhookWindowsHookEx(
            IntPtr hook);


        [DllImport("user32.dll")]
        private static extern IntPtr CallNextHookEx(
            IntPtr hook,
            int nCode,
            IntPtr wParam,
            IntPtr lParam);


        [DllImport("kernel32.dll")]
        private static extern IntPtr GetModuleHandle(
            string moduleName);


        [DllImport("kernel32.dll")]
        private static extern uint GetCurrentThreadId();


        [DllImport("user32.dll")]
        private static extern bool PostThreadMessage(
            uint threadId,
            uint message,
            IntPtr wParam,
            IntPtr lParam);


        [DllImport("user32.dll")]
        private static extern short GetAsyncKeyState(
            int virtualKey);


        [DllImport("kernel32.dll")]
        private static extern IntPtr GetStdHandle(
            int nStdHandle);


        [DllImport("kernel32.dll")]
        private static extern bool FlushConsoleInputBuffer(
            IntPtr hConsoleInput);


        [DllImport("user32.dll")]
        private static extern bool PeekMessage(
            out MSG message,
            IntPtr windowHandle,
            uint minimumMessage,
            uint maximumMessage,
            uint removeMessage);


        [DllImport("user32.dll")]
        private static extern int GetMessage(
            out MSG message,
            IntPtr windowHandle,
            uint minimumMessage,
            uint maximumMessage);


        [DllImport("user32.dll")]
        private static extern bool TranslateMessage(
            ref MSG message);


        [DllImport("user32.dll")]
        private static extern IntPtr DispatchMessage(
            ref MSG message);


        [StructLayout(LayoutKind.Sequential)]
        private struct MSG
        {
            public IntPtr hwnd;
            public uint message;
            public IntPtr wParam;
            public IntPtr lParam;
            public uint time;
            public int pointX;
            public int pointY;
        }
    }
}
