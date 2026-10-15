#!/usr/bin/env python3
"""Register a generic context-menu example without reading terminal contents."""

import iterm2


MENU_TITLE = "日志@演示"
MENU_ID = "local.iterm2-tools.logmenu-demo"
COMMAND = r"printf '%s\n' 'Hello from logmenu_demo!'"


async def main(connection):
    app = await iterm2.async_get_app(connection)

    @iterm2.ContextMenuProviderRPC
    async def insert_logmenu_demo(session_id=iterm2.Reference("id")):
        session = app.get_session_by_id(session_id)
        if session is None:
            print("Session no longer exists; no command was inserted.", flush=True)
            return
        # No newline: let the user inspect or edit the command before running it.
        await session.async_send_text(COMMAND, suppress_broadcast=True)

    await insert_logmenu_demo.async_register(connection, MENU_TITLE, MENU_ID)
    print("Registered context menu: " + MENU_TITLE, flush=True)


if __name__ == "__main__":
    iterm2.run_forever(main)
