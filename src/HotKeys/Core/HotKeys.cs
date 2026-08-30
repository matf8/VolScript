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

        private static int _volume50Key;
        private static int _volume50Modifier;
        private static int _volume100Key;
        private static int _volume100Modifier;
        private static int _exitKey;
        private static int _exitModifier;


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
            _volume50Key = volume50Key;
            _volume50Modifier = volume50Modifier;
            _volume100Key = volume100Key;
            _volume100Modifier = volume100Modifier;
            _exitKey = exitKey;
            _exitModifier = exitModifier;
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
            if (HotkeyModifierHelper.MatchesHotkey(
                _volume50Key,
                _volume50Modifier,
                virtualKeyCode))
            {
                return 1;
            }

            if (HotkeyModifierHelper.MatchesHotkey(
                _volume100Key,
                _volume100Modifier,
                virtualKeyCode))
            {
                return 2;
            }

            if (HotkeyModifierHelper.MatchesHotkey(
                _exitKey,
                _exitModifier,
                virtualKeyCode))
            {
                return 3;
            }

            return 0;
        }
    }
}
