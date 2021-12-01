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
	    [GtkChild]
	    private unowned Adw.ViewStack main_stack;
	    [GtkChild]
	    private unowned Gtk.Stack anime_stack;
	    [GtkChild]
	    private unowned Gtk.Stack manga_stack;
	    [GtkChild]
	    private unowned Gtk.Stack title_stack;
	    [GtkChild]
	    private unowned Gtk.Stack content_stack;
	    [GtkChild]
	    private unowned Gtk.ToggleButton search_button;
	    [GtkChild]
	    private unowned Gtk.SearchEntry search_entry;
	    [GtkChild]
	    private unowned Gtk.StackSidebar sidebar;

		public MainWindow(Gtk.Application app) {
			Object (application: app);
            if(BuildConfig.BUILD_TYPE == DEVEL) {
                get_style_context().add_class("devel");
            }

			loadData.begin();

            var default_page = AnilistGtkApp.instance.settings.get_string("default-page");
            switch(default_page) {
            case "anime":
                main_stack.visible_child = anime_stack;
                break;
            case "manga":
                main_stack.visible_child = manga_stack;
                break;
            }

            AnilistGtkApp.instance.settings.bind("width", this, "default-width", SettingsBindFlags.DEFAULT);
            AnilistGtkApp.instance.settings.bind("height", this, "default-height", SettingsBindFlags.DEFAULT);
            AnilistGtkApp.instance.settings.bind("is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

            main_stack.notify["visible-child"].connect(() => {
                sidebar.stack = (Gtk.Stack) main_stack.visible_child;
            });
            sidebar.stack = (Gtk.Stack) main_stack.visible_child;

            search_button.notify["active"].connect(() => {
                title_stack.visible_child_name = search_button.active ? "search" : "title";
                content_stack.visible_child_name = search_button.active ? "search" : "main";
                if (search_button.active)
                    search_entry.grab_focus();
                else {
                    search_entry.text = "";
                    search_button.grab_focus(); // If the entry stays focused, typing doesn't work properly anymore. Setting the focus to the search button makes the most sense
                }
            });

            search_entry.set_key_capture_widget(this);
            search_entry.search_started.connect(() => search_button.active = true);
            search_entry.stop_search.connect(() => search_button.active = false);

            search_entry.search_changed.connect(() => {

            });

            var sort_action = AnilistGtkApp.instance.settings.create_action("sort-by");
            add_action(sort_action);
		}

        public async void loadData() {
            var user = yield AnilistGtkApp.instance.client.get_user_info();
            message("username: %s", user.name);

            var animeLists = yield AnilistGtkApp.instance.client.get_media_lists(user.name, MediaType.ANIME);
            var anime_order = new Gee.ArrayList<string>.wrap(AnilistGtkApp.instance.settings.get_strv("anime-order"));

            animeLists.sort((a, b) => {
                var a_name = (a.isCustomList ? "CUSTOM_" : "") + a.name;
                var b_name = (b.isCustomList ? "CUSTOM_" : "") + b.name;
                return anime_order.index_of(a_name) - anime_order.index_of(b_name);
            });

		    foreach(var animeList in animeLists) {
		        var mediaListWidget = new MediaListWidget(animeList);
		        mediaListWidget.scrolledWindow.hscrollbar_policy = Gtk.PolicyType.NEVER;
                /*anime_search_entry.search_changed.connect(() => {
                    mediaListWidget.search = anime_search_entry.text;
                    mediaListWidget.listBox.invalidate_filter();
                });*/
                AnilistGtkApp.instance.settings.changed["sort-by"].connect(() => {
                    mediaListWidget.sort = AnilistGtkApp.instance.settings.get_string("sort-by");
                    mediaListWidget.listBox.invalidate_sort();
                });
                mediaListWidget.sort = AnilistGtkApp.instance.settings.get_string("sort-by");
                mediaListWidget.listBox.invalidate_sort();

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

		    var mangaLists = yield AnilistGtkApp.instance.client.get_media_lists(user.name, MediaType.MANGA);
		    var manga_order = new Gee.ArrayList<string>.wrap(AnilistGtkApp.instance.settings.get_strv("manga-order"));

            mangaLists.sort((a, b) => {
                var a_name = (a.isCustomList ? "CUSTOM_" : "") + a.name;
                var b_name = (b.isCustomList ? "CUSTOM_" : "") + b.name;
                return manga_order.index_of(a_name) - manga_order.index_of(b_name);
            });

		    foreach(var mangaList in mangaLists) {
		        var mediaListWidget = new MediaListWidget(mangaList);
		        mediaListWidget.scrolledWindow.hscrollbar_policy = Gtk.PolicyType.NEVER;
                /*manga_search_entry.search_changed.connect(() => {
                    mediaListWidget.search = manga_search_entry.text;
                    mediaListWidget.listBox.invalidate_filter();
                });*/
                AnilistGtkApp.instance.settings.changed["sort-by"].connect(() => {
                    mediaListWidget.sort = AnilistGtkApp.instance.settings.get_string("sort-by");
                    mediaListWidget.listBox.invalidate_sort();
                });
                mediaListWidget.sort = AnilistGtkApp.instance.settings.get_string("sort-by");
                mediaListWidget.listBox.invalidate_sort();

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
	}
}

