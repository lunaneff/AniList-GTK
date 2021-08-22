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
        // Apparently, this will be possible in the next version of Vala
        public Gtk.ScrolledWindow scrolledWindow {get; private set;}
        private Gtk.ListBox listBox;
        private MediaList mediaList;

        public MediaListWidget(MediaList list) {
            mediaList = list;
            scrolledWindow = new Gtk.ScrolledWindow();
            listBox = new Gtk.ListBox();
            listBox.selection_mode = Gtk.SelectionMode.NONE;

            foreach(var mediaListEntry in mediaList) {
                listBox.append(new MediaListEntryWidget(mediaListEntry));
            }

            scrolledWindow.child = listBox;
        }
    }
}
