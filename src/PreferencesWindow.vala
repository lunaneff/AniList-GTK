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
	[GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/PreferencesWindow.ui")]
    public class PreferencesWindow : Adw.PreferencesWindow {
        [GtkChild]
        private unowned Gtk.Switch blur_nsfw_switch;
        [GtkChild]
        private unowned Gtk.CheckButton default_page_radio_anime;
        [GtkChild]
        private unowned Gtk.CheckButton default_page_radio_manga;

		public PreferencesWindow() {
			AnilistGtkApp.instance.settings.bind("blur-nsfw", blur_nsfw_switch, "active", SettingsBindFlags.DEFAULT);

            update_default_page_radios();
			AnilistGtkApp.instance.settings.changed["default-page"].connect(update_default_page_radios);
			default_page_radio_anime.notify["active"].connect(update_default_page_setting);
			default_page_radio_manga.notify["active"].connect(update_default_page_setting);
		}

		private void update_default_page_radios() {
            var default_page = AnilistGtkApp.instance.settings.get_string("default-page");
            switch(default_page) {
            case "anime": // Anime
                default_page_radio_anime.active = true;
                break;
            case "manga": // Manga
                default_page_radio_manga.active = true;
                break;
            }
		}

		private void update_default_page_setting() {
		    if(default_page_radio_anime.active) {
		        AnilistGtkApp.instance.settings.set_string("default-page", "anime");
		    } else if(default_page_radio_manga.active) {
		        AnilistGtkApp.instance.settings.set_string("default-page", "manga");
		    }
		}
    }
}
