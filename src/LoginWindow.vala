/* LoginWindow.vala
 *
 * Copyright 2021 Laurin Neff <laurin@laurinneff.ch>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace AnilistGtk {
	[GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/LoginWindow.ui")]
    public class LoginWindow : Adw.ApplicationWindow {
        AnilistGtkApp app;

		public LoginWindow(AnilistGtkApp app) {
			Object (application: app);
		    this.app = app;
		}

        [GtkCallback]
		public void open_browser_login() {
		    try {
                AppInfo.launch_default_for_uri(AnilistClient.OAUTH_URI, null);
            } catch(Error e) {
                error(e.message);
            }
		}
    }
}
