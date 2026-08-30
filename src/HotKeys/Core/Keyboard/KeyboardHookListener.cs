using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using VolScript.HotKeys.Native;

namespace VolScript.HotKeys.Keyboard
{
    internal delegate void KeyboardHookHandler(
        int virtualKeyCode,
        bool isKeyDown);

    internal sealed class KeyboardHookListener
    {
        private IntPtr _hook = IntPtr.Zero;

        private LowLevelKeyboardProc _proc;

        private Thread _listenerThread;

        private uint _listenerThreadId;

        private KeyboardHookHandler _handler;


        internal uint ThreadId
        {
            get { return _listenerThreadId; }
        }


        internal void Start(
            KeyboardHookHandler handler)
        {
            Stop();

            _handler = handler;

            _proc = HookCallback;

            _listenerThread =
                new Thread(Listen);

            _listenerThread.IsBackground = true;

            _listenerThread.Start();
        }


        internal void Stop()
        {
            uint threadId = _listenerThreadId;

            if (threadId == 0)
            {
                return;
            }

            User32.PostThreadMessage(
                threadId,
                KeyboardConstants.WmQuit,
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
            _handler = null;
        }


        internal void WaitUntilReady()
        {
            while (_listenerThreadId == 0)
            {
                Thread.Sleep(10);
            }
        }


        private void Listen()
        {
            _listenerThreadId =
                Kernel32.GetCurrentThreadId();

            MSG message;

            User32.PeekMessage(
                out message,
                IntPtr.Zero,
                0,
                0,
                0);

            using (Process process = Process.GetCurrentProcess())
            using (ProcessModule module = process.MainModule)
            {
                _hook = User32.SetWindowsHookEx(
                    KeyboardConstants.WhKeyboardLl,
                    _proc,
                    Kernel32.GetModuleHandle(
                        module.ModuleName),
                    0);
            }

            if (_hook == IntPtr.Zero)
            {
                _listenerThreadId = 0;

                return;
            }

            while (
                User32.GetMessage(
                    out message,
                    IntPtr.Zero,
                    0,
                    0) > 0)
            {
                User32.TranslateMessage(ref message);

                User32.DispatchMessage(ref message);
            }

            Unhook();

            _listenerThreadId = 0;
        }


        private void Unhook()
        {
            if (_hook == IntPtr.Zero)
            {
                return;
            }

            User32.UnhookWindowsHookEx(_hook);

            _hook = IntPtr.Zero;
        }


        private IntPtr HookCallback(
            int nCode,
            IntPtr wParam,
            IntPtr lParam)
        {
            if (nCode >= 0 && _handler != null)
            {
                int message = wParam.ToInt32();

                bool isKeyDown =
                    message == KeyboardConstants.WmKeyDown ||
                    message == KeyboardConstants.WmSysKeyDown;

                bool isKeyUp =
                    message == KeyboardConstants.WmKeyUp ||
                    message == KeyboardConstants.WmSysKeyUp;

                if (isKeyDown || isKeyUp)
                {
                    int virtualKeyCode =
                        Marshal.ReadInt32(lParam);

                    _handler(
                        virtualKeyCode,
                        isKeyDown);
                }
            }

            return User32.CallNextHookEx(
                _hook,
                nCode,
                wParam,
                lParam);
        }
    }
}
