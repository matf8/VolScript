using System.Threading;
using VolScript.HotKeys.Keyboard;
using VolScript.HotKeys.Native;

namespace VolScript
{
    public static class VolScriptHotKeys
    {
        private static readonly KeyboardHookListener HookListener =
            new KeyboardHookListener();

        private static int _lastAction;

        private static int[] _keys = new int[0];
        private static int[] _modifiers = new int[0];
        private static int[] _actionIds = new int[0];


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
            int[] keys,
            int[] modifiers,
            int[] actionIds)
        {
            if (keys == null ||
                modifiers == null ||
                actionIds == null)
            {
                throw new System.ArgumentNullException(
                    "Hotkey binding arrays cannot be null.");
            }

            if (keys.Length != modifiers.Length ||
                keys.Length != actionIds.Length)
            {
                throw new System.ArgumentException(
                    "Hotkey binding arrays must have the same length.");
            }

            _keys = (int[])keys.Clone();
            _modifiers = (int[])modifiers.Clone();
            _actionIds = (int[])actionIds.Clone();
        }


        public static void Start()
        {
            if (HookListener.ThreadId != 0)
            {
                return;
            }

            _lastAction = 0;

            HookListener.Start(HandleKeyEvent);
        }


        public static void Stop()
        {
            HookListener.Stop();
        }


        private static void HandleKeyEvent(
            int virtualKeyCode,
            bool isKeyDown)
        {
            if (!isKeyDown)
            {
                return;
            }

            int action = GetAction(virtualKeyCode);

            if (action != 0)
            {
                Interlocked.Exchange(
                    ref _lastAction,
                    action);
            }
        }


        private static int GetAction(
            int virtualKeyCode)
        {
            for (int index = 0; index < _keys.Length; index++)
            {
                if (HotkeyModifierHelper.MatchesHotkey(
                    _keys[index],
                    _modifiers[index],
                    virtualKeyCode))
                {
                    return _actionIds[index];
                }
            }

            return 0;
        }
    }
}
