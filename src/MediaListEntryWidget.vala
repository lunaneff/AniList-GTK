/* MediaListEntryWidget.vala
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
    [GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/MediaListEntryWidget.ui")]
    public class MediaListEntryWidget : Gtk.Box {
        public MediaListEntry media_list_entry {get; private set;}
        private Gdk.Pixbuf cover_pixbuf;

        [GtkChild]
        private unowned Gtk.Picture cover;
        [GtkChild]
        private unowned Gtk.Label title;
        [GtkChild]
        private unowned Gtk.SpinButton progress;
        [GtkChild]
        private unowned Gtk.Label num_episodes_behind_label;
        [GtkChild]
        private unowned Gtk.Label next_airing_time;

        private Binding progress_binding;

        public MediaListEntryWidget() {
            progress.adjustment.step_increment = 1;

            AnilistGtkApp.instance.settings.changed["blur-nsfw"].connect(update_blur);
        }

        public async void setup(MediaListEntry entry) {
            media_list_entry = entry;
            title.label = media_list_entry.media.title.userPreferred;

            var progress_max = 0;
            if(media_list_entry.media.mediaType == ANIME) {
                progress_max = media_list_entry.media.episodes;
            } else if(media_list_entry.media.mediaType == MANGA) {
                progress_max = media_list_entry.media.chapters;
            }
            if(progress_max == 0) progress_max = int.MAX;

            progress.set_range(0, progress_max);
            progress_binding = media_list_entry.bind_property("progress", progress, "value", BIDIRECTIONAL|SYNC_CREATE);

            progress.notify["value"].connect(update_num_behind);
            update_num_behind();

            Timeout.add_seconds_full(Priority.DEFAULT, 60, update_next_airing_time);
            update_next_airing_time();

            update_blur();


            var cover_url = media_list_entry.media.coverImage.medium;
            var cover_filename = Checksum.compute_for_string(ChecksumType.SHA512, cover_url, cover_url.length) + ".png";
            var cover_file = File.new_build_filename(AnilistGtkApp.instance.cache_dir, "images", cover_filename[0:2], cover_filename);

            var parent = cover_file.get_parent();
            try {
                if(!parent.query_exists()) parent.make_directory_with_parents();
            } catch(Error err) {
                // According to the documentation, this should never be
                // reached, since we check if the directory already exists
                // beforehand. If we somehow still get here, just fail
                error(err.message);
            }

            if(cover_file.query_exists()) {
                try {
                    cover_pixbuf = yield new Gdk.Pixbuf.from_stream_async(yield cover_file.read_async());
                } catch(Error err) {
                    warning(err.message);
                }
            } else {
                // Reuse the session from the main AL client
                var session = AnilistGtkApp.instance.client.session;
                var msg = new Soup.Message("GET", cover_url);
                try {
                    var stream = yield session.send_async(msg);
                    cover_pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
                    cover_pixbuf.save(cover_file.get_path(), "png");
                } catch(Error err) {
                    warning(err.message);
                }
            }

            cover.set_pixbuf(cover_pixbuf);
        }

        public async void teardown() {
            media_list_entry = null;

            progress_binding.unbind();
            progress.notify["value"].disconnect(update_num_behind);

            // Since loading the image may take a bit, the wrong image might
            // be displayed for a while when the widget is recycled.
            cover.set_pixbuf(null);
        }

        private void update_num_behind() {
            var num_episodes_released = media_list_entry.media.nextAiringEpisode != null ?
                                        media_list_entry.media.nextAiringEpisode - 1 :
                                        media_list_entry.media.episodes;
            var num_episodes_behind = num_episodes_released - media_list_entry.progress;
            if(num_episodes_behind > 0) {
                num_episodes_behind_label.label = "%i episode%s behind".printf(num_episodes_behind, num_episodes_behind != 1 ? "s" : "");
                num_episodes_behind_label.visible = true;
            } else {
                num_episodes_behind_label.visible = false;
            }
        }

        private bool update_next_airing_time() {
            if(media_list_entry == null) return Source.REMOVE;

            if(media_list_entry.media.nextAiringEpisode != null) {
                var relative_next_airing_time = "in ";

                var now = new DateTime.now_utc();
                var diff = media_list_entry.media.nextAiringEpisodeDate.difference(now);

                var days = diff / TimeSpan.DAY;
                var hours = (diff - days * TimeSpan.DAY) / TimeSpan.HOUR;
                var minutes = (diff - days * TimeSpan.DAY - hours * TimeSpan.HOUR) / TimeSpan.MINUTE;

                if(diff > TimeSpan.DAY) {
                    relative_next_airing_time += "%id ".printf((int) days);
                }
                if(diff > TimeSpan.HOUR) {
                    relative_next_airing_time += "%ih ".printf((int) hours);
                }
                if(diff > TimeSpan.MINUTE) {
                    relative_next_airing_time += "%im ".printf((int) minutes);
                } else { // TODO: Hide the text some time after the episode airs
                    relative_next_airing_time = "now";
                }

                next_airing_time.label = "Episode %i airing %s".printf(
                    media_list_entry.media.nextAiringEpisode,
                    relative_next_airing_time
                );
                next_airing_time.visible = true;
            } else {
                next_airing_time.visible = false;
            }

            return Source.CONTINUE;
        }

        private void update_blur() {
            if(media_list_entry != null) {
                var blur = AnilistGtkApp.instance.settings.get_boolean("blur-nsfw");
                if(blur && media_list_entry.media.isAdult) {
                    cover.get_style_context().add_class("blur");
                } else {
                    cover.get_style_context().remove_class("blur");
                }
            }
        }
    }
}
