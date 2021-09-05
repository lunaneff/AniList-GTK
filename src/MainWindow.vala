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

	    [GtkChild]
	    private unowned Gtk.Stack main_stack;
	    [GtkChild]
	    private unowned Gtk.Box sidebar;
	    [GtkChild]
	    private unowned Adw.Leaflet leaflet;
	    [GtkChild]
	    private unowned Adw.ViewStack anime_stack;
	    [GtkChild]
	    private unowned Adw.ViewStack manga_stack;
	    [GtkChild]
	    private unowned Gtk.SearchEntry anime_search_entry;
	    [GtkChild]
	    private unowned Gtk.SearchEntry manga_search_entry;
	    [GtkChild]
	    private unowned Gtk.ComboBoxText anime_sort_combobox;
	    [GtkChild]
	    private unowned Gtk.ComboBoxText manga_sort_combobox;

		public MainWindow(Gtk.Application app, AnilistClient client) {
			Object (application: app);
			this.client = client;
			loadData.begin();

			var back_action = new SimpleAction("back", null);
			back_action.activate.connect(() => {
                leaflet.navigate(Adw.NavigationDirection.BACK);
			});
			add_action(back_action);
		}

		public async void loadData() {
		    var user = yield client.get_user_info();
		    message("username: %s", user.name);

		    var animeLists = yield client.get_media_lists(user.name, MediaType.ANIME);
		    foreach(var animeList in animeLists) {
		        var mediaListWidget = new MediaListWidget(animeList);
		        mediaListWidget.scrolledWindow.hscrollbar_policy = Gtk.PolicyType.NEVER;
                anime_search_entry.search_changed.connect(() => {
                    mediaListWidget.search = anime_search_entry.text;
                    mediaListWidget.listBox.invalidate_filter();
                });
                anime_sort_combobox.changed.connect(() => {
                    mediaListWidget.sort = anime_sort_combobox.get_active_id();
                    mediaListWidget.listBox.invalidate_sort();
                });

		        var settings = new GLib.Settings ("ch.laurinneff.AniList-GTK");
                settings.bind ("sort-by", anime_sort_combobox, "active_id", GLib.SettingsBindFlags.DEFAULT);

		        var page = anime_stack.add_titled(mediaListWidget.scrolledWindow, animeList.name, animeList.name);
		        if(!animeList.isCustomList) {
		            // I know this is a bad way of doing icons, but I'm not sure how to improve it
		            switch(animeList.name) {
	                case "Watching":
                        page.icon_name = "media-playback-start-symbolic";
	                    break;
	                case "Completed":
                        page.icon_name = "object-select-symbolic";
	                    break;
	                case "Planning":
                        page.icon_name = "x-office-calendar-symbolic";
	                    break;
	                case "Rewatching":
                        page.icon_name = "media-playlist-repeat-symbolic";
	                    break;
	                case "Paused":
                        page.icon_name = "media-playback-pause-symbolic";
	                    break;
	                case "Dropped":
                        page.icon_name = "media-playback-stop-symbolic";
	                    break;
		            }
		        }
		    }

		    var mangaLists = yield client.get_media_lists(user.name, MediaType.MANGA);
		    foreach(var mangaList in mangaLists) {
		        var mediaListWidget = new MediaListWidget(mangaList);
		        mediaListWidget.scrolledWindow.hscrollbar_policy = Gtk.PolicyType.NEVER;
                manga_search_entry.search_changed.connect(() => {
                    mediaListWidget.search = manga_search_entry.text;
                    mediaListWidget.listBox.invalidate_filter();
                });
                manga_sort_combobox.changed.connect(() => {
                    mediaListWidget.sort = manga_sort_combobox.get_active_id();
                    mediaListWidget.listBox.invalidate_sort();
                });
		        var page = manga_stack.add_titled(mediaListWidget.scrolledWindow, mangaList.name, mangaList.name);
		        if(!mangaList.isCustomList) {
		            // I know this is a bad way of doing icons, but I'm not sure how to improve it
		            switch(mangaList.name) {
	                case "Reading":
                        page.icon_name = "accessories-dictionary-symbolic";
	                    break;
	                case "Completed":
                        page.icon_name = "object-select-symbolic";
	                    break;
	                case "Planning":
                        page.icon_name = "x-office-calendar-symbolic";
	                    break;
	                case "Rereading":
                        page.icon_name = "media-playlist-repeat-symbolic";
	                    break;
	                case "Paused":
                        page.icon_name = "media-playback-pause-symbolic";
	                    break;
	                case "Dropped":
                        page.icon_name = "media-playback-stop-symbolic";
	                    break;
		            }
		        }
		    }
		}

		[GtkCallback]
		public void stack_changed(ParamSpec paramSpec) {
		    leaflet.set_visible_child(main_stack);
		}
	}
}

