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
        public MediaListEntry mediaListEntry {get; private set;}
        private Gdk.Pixbuf coverPixbuf;

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

        public MediaListEntryWidget(MediaListEntry entry) {
            mediaListEntry = entry;

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

            var num_episodes_released = mediaListEntry.media.nextAiringEpisode != null ?
                                        mediaListEntry.media.nextAiringEpisode :
                                        mediaListEntry.media.episodes;
            var num_episodes_behind = num_episodes_released - mediaListEntry.progress;
            if(num_episodes_behind > 0) {
                num_episodes_behind_label.label = "%i episode%s behind".printf(num_episodes_behind, num_episodes_behind != 0 ? "s" : "");
            }

            if(mediaListEntry.media.nextAiringEpisode != null) {
                var relative_next_airing_time = "in ";
                {
                    var now = new DateTime.now_utc();
                    var diff = mediaListEntry.media.nextAiringEpisodeDate.difference(now);

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
                    } else {
                        relative_next_airing_time = "now";
                    }
                }

                next_airing_time.label = "Episode %i airing %s".printf(
                    mediaListEntry.media.nextAiringEpisode,
                    relative_next_airing_time
                );
            }

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
            try {
                var filename = Path.get_basename(Uri.parse(mediaListEntry.media.coverImage.medium, UriFlags.NONE).get_path());
                var file = File.new_build_filename(AnilistGtkApp.instance.cache_dir, "images", filename);
                var parent = file.get_parent();
                if(!parent.query_exists()) parent.make_directory_with_parents();
                if(file.query_exists()) {
                    coverPixbuf = yield new Gdk.Pixbuf.from_stream_async(file.read());
                } else {
                    message("Loading image for %s", mediaListEntry.media.title.userPreferred);

                    // Threading code based on https://wiki.gnome.org/Projects/Vala/AsyncSamples#Background_thread_example
                    SourceFunc callback = load_image.callback;
                    Gdk.Pixbuf[] output = new Gdk.Pixbuf[1];

                    ThreadFunc<void> run = () => {
                        try {
                            var session = new Soup.Session();
                            var msg = new Soup.Message("GET", mediaListEntry.media.coverImage.medium);
                            var stream = session.send(msg);
                            var pixbuf = new Gdk.Pixbuf.from_stream(stream);
                            output[0] = pixbuf;
                        } catch(Error e) {
                            warning("failed to load cover image: %s", e.message);
                        }
                        Idle.add((owned) callback);
                        return;
                    };
                    new Thread<void>("load-image", run);

                    yield;
                    coverPixbuf = output[0];
                    coverPixbuf.save(file.get_path(), "jpeg");
                }
                update_blur();
                AnilistGtkApp.instance.settings.changed["blur-nsfw"].connect(update_blur);

		        cover.set_pixbuf(coverPixbuf);
                message("Loaded image for %s", mediaListEntry.media.title.userPreferred);
            } catch(Error e) {
                warning("failed to load cover image: %s", e.message);
            }
        }

        public void update_blur() {
            var blur = AnilistGtkApp.instance.settings.get_boolean("blur-nsfw");
            if(blur && mediaListEntry.media.isAdult) {
                cover.get_style_context().add_class("blur");
            } else {
                cover.get_style_context().remove_class("blur");
            }
        }
    }
}
