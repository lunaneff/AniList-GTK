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
    [GtkTemplate (ui = "/ch/laurinneff/AniList-GTK/ui/MediaListReordererRowWidget.ui")]
    public class MediaListReordererRowWidget : Adw.PreferencesRow {
        public signal void dropped(MediaListReordererRowWidget row, Gtk.PositionType position);

        [GtkChild]
        private unowned Adw.ActionRow action_row;
        [GtkChild]
        private unowned Gtk.Revealer top_revealer;
        [GtkChild]
        private unowned Gtk.Revealer bottom_revealer;

        private MediaListEntryStatus _status;
        public MediaListEntryStatus status {
            get {
                return _status;
            }
            set {
                _status = value;
                title = value.to_human_string();
            }
        }

        public MediaListReordererRowWidget() {
            var source = new Gtk.DragSource() {
                actions = MOVE,
            };

            source.prepare.connect((x, y) => {
                var snapshot = new Gtk.Snapshot();
                this.snapshot(snapshot);
                source.set_icon(snapshot.to_paintable(null), 0, 0);
                return new Gdk.ContentProvider.for_value(this);
            });

            this.add_controller(source);

            var target = new Gtk.DropTarget(typeof(MediaListReordererRowWidget), MOVE);

            target.motion.connect ((target, x, y) => {
                if(y < get_height() / 2) {
                    top_revealer.reveal_child = true;
                    bottom_revealer.reveal_child = false;
                } else if(y >= get_height() / 2) {
                    top_revealer.reveal_child = false;
                    bottom_revealer.reveal_child = true;
                }

                return MOVE;
            });

            target.leave.connect (() => {
                top_revealer.reveal_child = false;
                bottom_revealer.reveal_child = false;
            });

            target.on_drop.connect ((target, value, x, y) => {
                if((MediaListReordererRowWidget) value == this) return false;

                if(y < get_height() / 2) {
                    dropped((MediaListReordererRowWidget) value, TOP);
                } else if(y >= get_height() / 2) {
                    dropped((MediaListReordererRowWidget) value, BOTTOM);
                }

                return true;
            });

            this.add_controller(target);

            bind_property("title", action_row, "title", DEFAULT);
        }
    }
}
