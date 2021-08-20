/* MainWindow.vala
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
	[GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/MainWindow.ui")]
	public class MainWindow : Adw.ApplicationWindow {
	    private AnilistClient client;

		public MainWindow(Gtk.Application app, AnilistClient client) {
			Object (application: app);
			this.client = client;
			loadData.begin();
		}

		public async void loadData() {
		    var user = yield client.get_user_info();
		    message("username: %s", user.name);
		    var animeLists = yield client.get_media_lists(user.name, MediaType.ANIME);
		    foreach(var animeList in animeLists) {
		        message ("Anime list: %s", animeList.name);
		        foreach(var mediaListEntry in animeList) {
		            message(
		                "entry id: %i, title: %s, progress: %i/%i",
		                mediaListEntry.id,
		                mediaListEntry.media.title.userPreferred,
		                mediaListEntry.progress,
		                mediaListEntry.media.episodes
		            );
		        }
		    }
		}
	}
}

