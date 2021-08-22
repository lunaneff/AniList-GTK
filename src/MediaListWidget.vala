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

        public MediaListWidget(MediaList list) {
            mediaList = list;
            scrolledWindow = new Gtk.ScrolledWindow();
            listBox = new Gtk.ListBox();
            listBox.selection_mode = Gtk.SelectionMode.NONE;

            foreach(var mediaListEntry in mediaList) {
                listBox.append(new MediaListEntryWidget(mediaListEntry));
            }

            scrolledWindow.child = listBox;

            listBox.set_filter_func ((row) => {
                // TODO: Need to implement proper filter function
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
        }
    }
}
