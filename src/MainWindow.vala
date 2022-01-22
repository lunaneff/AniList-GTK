/* MainWindow.vala
 *
 * Copyright 2021-2022 Laurin Neff <laurin@laurinneff.ch>
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
	    private unowned Adw.Flap flap;
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

			load_data.begin();

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

            anime_stack.notify["visible-child"].connect(() => {
                if(flap.folded) flap.reveal_flap = false;
            });
            manga_stack.notify["visible-child"].connect(() => {
                if(flap.folded) flap.reveal_flap = false;
            });

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

        public async void load_data() {
            yield load_lists(ANIME, new Gee.ArrayList<string>.wrap(AnilistGtkApp.instance.settings.get_strv("anime-order")), anime_stack);
            yield load_lists(MANGA, new Gee.ArrayList<string>.wrap(AnilistGtkApp.instance.settings.get_strv("manga-order")), manga_stack);
		}

		public async List<Gtk.StackPage> load_lists(MediaType type, Gee.List<string> order, Gtk.Stack stack) {
            var user = yield AnilistGtkApp.instance.client.get_user_info();

		    var lists = yield AnilistGtkApp.instance.client.get_media_lists(user.name, type);

            lists.sort((a, b) => {
                var a_name = (a.isCustomList ? "CUSTOM_" : "") + a.name;
                var b_name = (b.isCustomList ? "CUSTOM_" : "") + b.name;
                return order.index_of(a_name) - order.index_of(b_name);
            });

            var pages = new List<Gtk.StackPage>();

            foreach (var list in lists) {
                var sorter = new Gtk.CustomSorter((a, b) => {
                    if(a is MediaListEntry && b is MediaListEntry) {
                        var sort = AnilistGtkApp.instance.settings.get_string("sort-by");
                        var entry1 = (MediaListEntry) a;
                        var entry2 = (MediaListEntry) b;
                        int retval = 0;
                        bool reverse = false;
                        if(sort[0] == '-') reverse = true;
                        string sort_type = sort;
                        if(reverse) sort_type = sort_type[1:];

                        switch(sort_type) {
                        case "alpha":
                            if(entry1.media.title.userPreferred.down() > entry2.media.title.userPreferred.down())
                                retval = 1;
                            else retval = -1;
                            break;
                        case "progress":
                            if(entry1.progress > entry2.progress)
                                retval = 1;
                            else retval = -1;
                            break;
                        case "rating":
                            if(entry1.score > entry2.score)
                                retval = 1;
                            else retval = -1;
                            break;
                        case "update":
                            if(entry1.updatedAt.to_unix() > entry2.updatedAt.to_unix())
                                retval = -1;
                            else retval = 1;
                            break;
                        case "upcoming":
                            if(entry1.media.nextAiringEpisodeDate.to_unix() > entry2.media.nextAiringEpisodeDate.to_unix())
                                retval = 1;
                            else retval = -1;
                            break;
                        }

                        if(reverse) retval = -retval;
                        return retval;
                    } else return 0;
                });

                AnilistGtkApp.instance.settings.changed["sort-by"].connect(() => {
                    // TODO: Detect if the order was just inverted, and if so, pass INVERTED instead (to make resorting faster)
                    sorter.changed(DIFFERENT);
                });

                var sort_model = new Gtk.SortListModel(list.list_store, sorter) {
                    incremental = true
                };

                var selection_model = new Gtk.NoSelection(sort_model);

                var factory = new Gtk.SignalListItemFactory();
                factory.setup.connect((listitem) => {
                    var media_list_entry_widget = new MediaListEntryWidget();
                    listitem.child = media_list_entry_widget;
                });
                factory.teardown.connect((listitem) => {
                    listitem.child.destroy();
                    listitem.child = null;
                });
                factory.bind.connect((listitem) => {
                    var media_list_entry_widget = (MediaListEntryWidget) listitem.child;
                    media_list_entry_widget.setup.begin((MediaListEntry) listitem.item);
                });
                factory.unbind.connect((listitem) => {
                    var media_list_entry_widget = (MediaListEntryWidget) listitem.child;
                    media_list_entry_widget.teardown.begin();
                });

                var list_view = new Gtk.ListView(selection_model, factory) {
                    show_separators = true
                };
                var scrolled_window = new Gtk.ScrolledWindow();
                scrolled_window.child = list_view;

                pages.append(stack.add_titled(scrolled_window, list.name, list.name));
            }

            return pages;
		}
	}
}

