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
    [GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/MediaListEntryWidget.ui")]
    public class MediaListEntryWidget : Gtk.ListBoxRow {
        private MediaListEntry mediaListEntry;
        private Gdk.Pixbuf coverPixbuf;

        [GtkChild]
        private unowned Gtk.Image cover;
        [GtkChild]
        private unowned Gtk.Label title;
        [GtkChild]
        private unowned Gtk.SpinButton progress;

        public MediaListEntryWidget(MediaListEntry entry) {
            mediaListEntry = entry;
            cover.height_request = 150;
            cover.width_request = cover.height_request/3*2; // Recommended aspect ratio for covers on AniList is 2:3

            title.label = mediaListEntry.media.title.userPreferred;

            var progressMax = 0;
            if(mediaListEntry.media.mediaType == MediaType.ANIME) {
                progressMax = mediaListEntry.media.episodes;
            } else if (mediaListEntry.media.mediaType == MediaType.MANGA) {
                progressMax = mediaListEntry.media.chapters;
            }
            if(progressMax == 0) progressMax = int.MAX;

            progress.adjustment.step_increment = 1;
            progress.set_range(0, progressMax);
            progress.value = mediaListEntry.progress;

            progress.value_changed.connect((type) => {
                message("progress change");
            });

            show.connect(show_handler);
            load_image.begin();
        }

        public void show_handler() {
            message("show");
        }

        public async void load_image() {
            var session = new Soup.Session();
            var msg = new Soup.Message("GET", mediaListEntry.media.coverImage.large);
            var stream = yield session.send_async(msg);
            coverPixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
		    cover.set_from_pixbuf(coverPixbuf);
        }
    }
}
