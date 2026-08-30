using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace VolScript
{
    public static class VolScriptHotKeys
    {
        // ============================================================
        // Windows constants
        // ============================================================

        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_QUIT = 0x0012;


        // ============================================================
        // State
        // ============================================================

        private static IntPtr _hook = IntPtr.Zero;

        private static LowLevelKeyboardProc _proc =
            HookCallback;

        private static Thread _listenerThread;

        private static uint _listenerThreadId;

        private static int _lastAction;

        private static int _volume50Key;

        private static int _volume50Modifier;

        private static int _volume100Key;

        private static int _volume100Modifier;

        private static int _exitKey;

        private static int _exitModifier;


        // ============================================================
        // Public API
        // ============================================================

        public static int LastAction
        {
            get
            {
                return Interlocked.Exchange(
                    ref _lastAction,
                    0);
            }
        }


        public static void Configure(
            int volume50Key,
            int volume50Modifier,
            int volume100Key,
            int volume100Modifier,
            int exitKey,
            int exitModifier)
        {
            _volume50Key =
                volume50Key;

            _volume50Modifier =
                volume50Modifier;

            _volume100Key =
                volume100Key;

            _volume100Modifier =
                volume100Modifier;

            _exitKey =
                exitKey;

            _exitModifier =
                exitModifier;
        }


        public static void Start()
        {
            if (
                _listenerThread != null &&
                _listenerThread.IsAlive)
            {
                return;
            }

            _lastAction = 0;

            _listenerThread =
                new Thread(Listen);

            _listenerThread.IsBackground = true;

            _listenerThread.Start();
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
        }


        // ============================================================
        // Listener
        // ============================================================

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


        // ============================================================
        // Keyboard handling
        // ============================================================

        private delegate IntPtr LowLevelKeyboardProc(
            int nCode,
            IntPtr wParam,
            IntPtr lParam);


        private static bool IsKeyDown(
            int nCode,
            IntPtr wParam)
        {
            return
                nCode >= 0 &&
                wParam == (IntPtr)WM_KEYDOWN;
        }


        private static int GetAction(
            int virtualKeyCode)
        {
            if (IsHotkeyPressed(
                _volume50Key,
                _volume50Modifier,
                virtualKeyCode))
            {
                return 1;
            }

            if (IsHotkeyPressed(
                _volume100Key,
                _volume100Modifier,
                virtualKeyCode))
            {
                return 2;
            }

            if (IsHotkeyPressed(
                _exitKey,
                _exitModifier,
                virtualKeyCode))
            {
                return 3;
            }

            return 0;
        }


        private static bool IsHotkeyPressed(
            int key,
            int modifier,
            int virtualKeyCode)
        {
            if (virtualKeyCode != key)
            {
                return false;
            }

            if (modifier == 0)
            {
                return true;
            }

            return (
                GetAsyncKeyState(
                    modifier) &
                0x8000
            ) != 0;
        }


        private static IntPtr HookCallback(
            int nCode,
            IntPtr wParam,
            IntPtr lParam)
        {
            if (!IsKeyDown(
                nCode,
                wParam))
            {
                return CallNextHookEx(
                    _hook,
                    nCode,
                    wParam,
                    lParam);
            }

            int virtualKeyCode =
                Marshal.ReadInt32(
                    lParam);

            int action =
                GetAction(
                    virtualKeyCode);

            if (action != 0)
            {
                Interlocked.Exchange(
                    ref _lastAction,
                    action);
            }

            return CallNextHookEx(
                _hook,
                nCode,
                wParam,
                lParam);
        }


        // ============================================================
        // Windows API
        // ============================================================

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


        // ============================================================
        // Windows message
        // ============================================================

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