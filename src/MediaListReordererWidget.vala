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
    public class MediaListReordererWidget : Adw.PreferencesGroup {
        private MediaListEntryStatus[] options = {
            CURRENT,
            COMPLETED,
            PLANNING,
            REPEATING,
            PAUSED,
            DROPPED
        };

        private string _setting;
        public string setting {
            get { return _setting; }
            set {
                message("Update order setting: %s", value);
                _setting = value;
            }
        }

        public MediaListReordererWidget() {
            foreach(var option in options) {
                var row = new MediaListReordererRowWidget() {status = option};
                row.dropped.connect((other, position) => {
                    var position_class = (EnumClass) typeof(Gtk.PositionType).class_ref();
                    message("Row \"%s\" was dropped on \"%s\", will be inserted on %s", other.status.to_human_string(), row.status.to_human_string(), position_class.get_value(position).value_name);
                });
                add(row);
            }
        }
    }
}
