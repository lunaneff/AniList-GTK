/* MediaListEntryWidget.vala
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
    public class MediaListWidget : Object {
        // For some reason, you can't subclass a ScrolledWindow
        public Gtk.ScrolledWindow scrolledWindow {get; private set;}
        public Gtk.ListBox listBox {get; private set;}
        private MediaList mediaList;

        public string search = "";
        public string sort = "";

        public MediaListWidget(MediaList list) {
            mediaList = list;
            scrolledWindow = new Gtk.ScrolledWindow();
            listBox = new Gtk.ListBox() {
                show_separators = true
            };
            listBox.selection_mode = Gtk.SelectionMode.NONE;

            foreach(var mediaListEntry in mediaList) {
                listBox.append(new MediaListEntryWidget(mediaListEntry));
            }

            scrolledWindow.child = listBox;

            listBox.set_filter_func ((row) => {
                if(row is MediaListEntryWidget) {
                    var entry = (MediaListEntryWidget) row;

                    if(search == "") return true;

                    if(entry.mediaListEntry.media.title.english.down().contains(search.down()) ||
                        entry.mediaListEntry.media.title.native.down().contains(search.down()) ||
                        entry.mediaListEntry.media.title.romaji.down().contains(search.down())) {
                        return true;
                    } else return false;
                } else return false;
            });

            listBox.set_sort_func ((row1, row2) => {
                if(row1 is MediaListEntryWidget && row2 is MediaListEntryWidget) {
                    var entry1 = (MediaListEntryWidget) row1;
                    var entry2 = (MediaListEntryWidget) row2;
                    int retval = 0;
                    bool reverse = false;
                    if(sort[0] == '-') reverse = true;
                    string sort_type = sort;
                    if(reverse) sort_type = sort_type[1:];

                    switch(sort_type) {
                    case "alpha":
                        if(entry1.mediaListEntry.media.title.userPreferred.down() > entry2.mediaListEntry.media.title.userPreferred.down())
                            retval = 1;
                        else retval = -1;
                        break;
                    case "progress":
                        if(entry1.mediaListEntry.progress > entry2.mediaListEntry.progress)
                            retval = 1;
                        else retval = -1;
                        break;
                    case "rating":
                        if(entry1.mediaListEntry.score > entry2.mediaListEntry.score)
                            retval = 1;
                        else retval = -1;
                        break;
                    case "update":
                        if(entry1.mediaListEntry.updatedAt.to_unix() > entry2.mediaListEntry.updatedAt.to_unix())
                            retval = -1;
                        else retval = 1;
                        break;
                    case "upcoming":
                        if(entry1.mediaListEntry.media.nextAiringEpisodeDate.to_unix() > entry2.mediaListEntry.media.nextAiringEpisodeDate.to_unix())
                            retval = 1;
                        else retval = -1;
                        break;
                    }

                    if(reverse) retval = -retval;
                    return retval;
                } else return 0;
            });
        }
    }
}
