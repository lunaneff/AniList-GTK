/* AniList.vala
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
    public class AnilistClient : Object {
        public const int OAUTH_CLIENT_ID = 5986;
        // Not const because valac wouldn't compile with the template string
        public static string OAUTH_URI = @"https://anilist.co/api/v2/oauth/authorize?client_id=$OAUTH_CLIENT_ID&response_type=token";

        public bool is_logged_in {
            get {
                return false;
            }
        }
    }
}

