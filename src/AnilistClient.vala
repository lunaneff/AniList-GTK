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

using Gee;

namespace AnilistGtk {
    public class AnilistClient : Object {
        public const int OAUTH_CLIENT_ID = 5986;
        // Not const because valac wouldn't compile with the template string
        public static string OAUTH_URI = @"https://anilist.co/api/v2/oauth/authorize?client_id=$OAUTH_CLIENT_ID&response_type=token";
        public const string API_URL = "https://graphql.anilist.co";

        public Secret.Schema token_schema;

        private string token;
        public string anilist_token {
            get {
                return token;
            }
        }

        public Soup.Session session;

        private AnilistGtkApp app;

        public AnilistClient(AnilistGtkApp app) {
            token_schema = new Secret.Schema("ch.laurinneff.AniList-GTK.Token", Secret.SchemaFlags.NONE,
                                             "is-anilist-token", Secret.SchemaAttributeType.BOOLEAN, null);
            session = new Soup.Session();
            this.app = app;
        }

        public async void store_token(string token) {
            try {
                this.token = token;
                bool res = yield Secret.password_store(token_schema, Secret.COLLECTION_DEFAULT,
                                                       "AniList-GTK Token", token, null, "is-anilist-token", true, null);

                message("stored token, res: %s", res ? "true" : "false");
            } catch(Error e) {
                warning("failed to store token: %s", e.message);
            }
        }

        public async string? get_token() {
            try {
                // TODO: Figure out why it doesn't return when I use the async version
                string token = Secret.password_lookup_sync(token_schema, null, "is-anilist-token", true, null);
                this.token = token;
                return token;
            } catch(Error e) {
                warning("failed to get token: %s", e.message);
                return null;
            }
        }

        public async void delete_token() {
            try {
                var res = yield Secret.password_clear(token_schema, null, "is-anilist-token", true, null);

                message("deleted token, res: %s", res ? "true" : "false");
            } catch(Error e) {
                warning("failed to delete token: %s", e.message);
            }
        }

        public async bool check_logged_in() {
            if(anilist_token == null) {
                return false;
            }
            var res = yield get_user_info();
            if(res != null) {
                return true;
            }
            return false;
        }

        public async User get_user_info() {
            uint8[] graphql;
            try {
                yield File.new_for_uri("resource:///ch/laurinneff/AniList-GTK/graphql/user.graphql").load_contents_async(null, out graphql, null);
            } catch(Error e) {
                warning("failed to get graphql file: %s", e.message);
            }

            var variables = new HashMap<string, string>();

            var res = yield graphql_request((string) graphql, variables);
            var user = new User(res.get_object_member("Viewer"));
            return user;
        }

        public async ArrayList<MediaList> get_media_lists(string user, MediaType type) {
            uint8[] graphql;
            try {
                yield File.new_for_uri("resource:///ch/laurinneff/AniList-GTK/graphql/media_list.graphql").load_contents_async(null, out graphql, null);
            } catch(Error e) {
                warning("failed to get graphql file: %s", e.message);
            }

            string strType = type.to_string();

            var variables = new HashMap<string, string>();
            variables["userName"] = user;
            variables["type"] = strType;

            var res = yield graphql_request((string) graphql, variables);

            var mediaLists = new ArrayList<MediaList>();
            foreach(var listNode in res.get_object_member("MediaListCollection").get_array_member("lists").get_elements()) {
                var list = listNode.get_object();
                mediaLists.add(new MediaList(list));
            }

            return mediaLists;
        }

        public async Json.Object? graphql_request(string graphql, HashMap<string, string> variables) {
            var msg = new Soup.Message("POST", API_URL);
            msg.request_headers.append("Authorization", @"Bearer $anilist_token");
            msg.request_headers.append("Content-Type", "application/json");
            msg.request_headers.append("Accept", "application/json");

            var gen = new Json.Generator();
            { // Generate JSON inside of a block so that the same variable names can be used for generating and parsing
                var root = new Json.Node(Json.NodeType.OBJECT);
                var root_object = new Json.Object();
                root.set_object(root_object);
                gen.set_root(root);
                root_object.set_string_member("query", graphql);

                var vars_object = new Json.Object();
                foreach (var variable in variables) {
                    vars_object.set_string_member(variable.key, variable.value);
                }
                root_object.set_object_member("variables", vars_object);
            }

            var json = gen.to_data(null);
            debug("Sending request with data %s", json);
            msg.request_body.append_take(json.data);

            var parser = new Json.Parser();

            try {
                var stream = yield session.send_async(msg);
                var dis = new DataInputStream(stream);
                var data = yield dis.read_upto_async("\0", 1, Priority.DEFAULT, null, null);
                debug("Got response from AniList: %s", data);
                parser.load_from_data(data);
            } catch(Error e) {
                var text = "Failed to send request to AniList API: %s".printf(e.message);
                warning(text);
                var dialog = new Gtk.MessageDialog(app.active_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, text);
                dialog.title = "API request failed";
                dialog.response.connect(() => dialog.destroy());
                dialog.present();
            }

            {
                var root = parser.get_root();
                var root_object = root.get_object();
                if(root_object.has_member("errors")) {
                    var errors = root_object.get_array_member("errors");
                    errors.foreach_element((arr, i, elem) => {
                        var error_object = elem.get_object();
                        var text = "Error returned from AniList: Status %d, msg: %s".printf((int) error_object.get_int_member("status"), error_object.get_string_member("message"));
                        warning(text);
                        var dialog = new Gtk.MessageDialog(app.active_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, text);
                        dialog.title = "AniList returned an error";
                        dialog.response.connect(() => dialog.destroy());
                        dialog.present();
                    });
                } else if (root_object.has_member("data")) {
                    return root_object.get_object_member("data");
                }
            }

            return null;
        }
    }

    public class MediaList : ArrayList<MediaListEntry> {
        public string name {get; private set;}
        public bool isCustomList {get; private set;}

        public MediaList(Json.Object jsonList) {
            this.name = jsonList.get_string_member("name");
            this.isCustomList = jsonList.get_boolean_member("isCustomList");

            foreach(var entryNode in jsonList.get_array_member("entries").get_elements()) {
                var entry = entryNode.get_object();
                this.add(new MediaListEntry(entry));
            }
        }
    }

    public class MediaListEntry : Object {
        public int id {get; private set;}
        public MediaListEntryStatus status {get; private set;}
        public double score {get; private set;}
        public int progress {get; private set;}
        public int progressVolumes {get; private set;}
        public int repeat {get; private set;}
        public int priority {get; private set;}
        public bool private {get; private set;}
        public bool hiddenFromStatusLists {get; private set;}
        // TODO: add customLists property (not implemented as I don't know the format the API returns this in)
        // TODO: add advancedScores property
        public string notes {get; private set;}
        public DateTime updatedAt {get; private set;}
        public Date startedAt {get; private set;}
        public Date completedAt {get; private set;}
        public Media media {get; private set;}

        public MediaListEntry(Json.Object jsonEntry) {
            this.id = (int) jsonEntry.get_int_member("id");

            this.status = MediaListEntryStatus.from_string(jsonEntry.get_string_member("status"));

            this.score = jsonEntry.get_double_member("score");
            this.progress = (int) jsonEntry.get_int_member("progress");
            this.progressVolumes = (int) jsonEntry.get_int_member("progressVolumes");
            this.repeat = (int) jsonEntry.get_int_member("repeat");
            this.priority = (int) jsonEntry.get_int_member("priority");
            this.private = jsonEntry.get_boolean_member("private");
            this.hiddenFromStatusLists = jsonEntry.get_boolean_member("hiddenFromStatusLists");
            this.notes = jsonEntry.get_string_member("notes");
            this.updatedAt = new DateTime.from_unix_utc(jsonEntry.get_int_member("updatedAt"));

            var jsonStartedAt = jsonEntry.get_object_member("startedAt");
            {
                var day = (DateDay) jsonStartedAt.get_int_member("day"),
                    month = (int) jsonStartedAt.get_int_member("month"),
                    year = (DateYear) jsonStartedAt.get_int_member("year");
                // Ask the GLib devs why they decided to use DateMonth in valid_dmy and int in set_dmy, I don't know why
                if(Date.valid_dmy(day, (DateMonth) month, year)) {
                    this.startedAt = Date();
                    this.startedAt.set_dmy(day, month, year);
                }
            }

            var jsonCompletedAt = jsonEntry.get_object_member("completedAt");
            {
                var day = (DateDay) jsonCompletedAt.get_int_member("day"),
                    month = (int) jsonCompletedAt.get_int_member("month"),
                    year = (DateYear) jsonCompletedAt.get_int_member("year");
                if(Date.valid_dmy(day, (DateMonth) month, year)) {
                    this.completedAt = Date();
                    this.completedAt.set_dmy(day, month, year);
                }
            }

            this.media = new Media(jsonEntry.get_object_member("media"));
        }
    }

    public class Media : Object {
        public int id {get; private set;}
        public MediaTitle title {get; private set;}
        public MediaCoverImage coverImage {get; private set;}
        public MediaType mediaType {get; private set;}
        public MediaFormat format {get; private set;}
        public MediaStatus status {get; private set;}
        public int episodes {get; private set;}
        public int volumes {get; private set;}
        public int chapters {get; private set;}
        public int averageScore {get; private set;}
        public int popularity {get; private set;}
        public bool isAdult {get; private set;}
        public string countryOfOrigin {get; private set;}
        public ArrayList<string> genres {get; private set;}
        public string bannerImage {get; private set;}
        public Date startDate {get; private set;}
        public Date endDate {get; private set;}
        public int? nextAiringEpisode {get; private set;}
        public DateTime nextAiringEpisodeDate {get; private set;}

        public Media(Json.Object jsonMedia) {
            this.id = (int) jsonMedia.get_int_member("id");
            this.title = new MediaTitle(jsonMedia.get_object_member("title"));
            this.coverImage = new MediaCoverImage(jsonMedia.get_object_member("coverImage"));

            this.mediaType = MediaType.from_string(jsonMedia.get_string_member("type"));

            this.format = MediaFormat.from_string(jsonMedia.get_string_member("format"));

            this.status = MediaStatus.from_string(jsonMedia.get_string_member("status"));

            this.episodes = (int) jsonMedia.get_int_member("episodes");
            this.volumes = (int) jsonMedia.get_int_member("volumes");
            this.chapters = (int) jsonMedia.get_int_member("chapters");
            this.averageScore = (int) jsonMedia.get_int_member("averageScore");
            this.popularity = (int) jsonMedia.get_int_member("popularity");
            this.isAdult = jsonMedia.get_boolean_member("isAdult");
            this.countryOfOrigin = jsonMedia.get_string_member("countryOfOrigin");

            this.genres = new ArrayList<string>();
            foreach (var genre in jsonMedia.get_array_member("genres").get_elements()) {
                this.genres.add(genre.get_string());
            }

            this.bannerImage = jsonMedia.get_string_member("bannerImage");

            {
                var jsonStartDate = jsonMedia.get_object_member("startDate");
                var day = (DateDay) jsonStartDate.get_int_member("day"),
                    month = (int) jsonStartDate.get_int_member("month"),
                    year = (DateYear) jsonStartDate.get_int_member("year");
                if(Date.valid_dmy(day, (DateMonth) month, year)) {
                    this.startDate = Date();
                    this.startDate.set_dmy(day, month, year);
                }
            }

            {
                var jsonEndDate = jsonMedia.get_object_member("endDate");
                var day = (DateDay) jsonEndDate.get_int_member("day"),
                    month = (int) jsonEndDate.get_int_member("month"),
                    year = (DateYear) jsonEndDate.get_int_member("year");
                if(Date.valid_dmy(day, (DateMonth) month, year)) {
                    this.endDate = Date();
                    this.endDate.set_dmy(day, month, year);
                }
            }

            var nextAiringEpisode = jsonMedia.get_member("nextAiringEpisode");
            if(!nextAiringEpisode.is_null()) {
                var nextAiringEpisodeObj = nextAiringEpisode.get_object();
                this.nextAiringEpisode = (int) nextAiringEpisodeObj.get_int_member("episode");
                this.nextAiringEpisodeDate = new DateTime.from_unix_utc(nextAiringEpisodeObj.get_int_member("airingAt"));
            } else {
                this.nextAiringEpisode = null;
                this.nextAiringEpisodeDate = null;
            }
        }
    }

    public class MediaTitle : Object {
        public string userPreferred {get; private set;}
        public string romaji {get; private set;}
        public string english {get; private set;}
        public string native {get; private set;}

        public MediaTitle(Json.Object jsonMediaTitle) {
            this.userPreferred = jsonMediaTitle.get_string_member_with_default("userPreferred", "");
            this.romaji = jsonMediaTitle.get_string_member_with_default("romaji", "");
            this.english = jsonMediaTitle.get_string_member_with_default("english", "");
            this.native = jsonMediaTitle.get_string_member_with_default("native", "");
        }
    }

    public class MediaCoverImage : Object {
        public string extraLarge {get; private set;}
        public string large {get; private set;}
        public string medium {get; private set;}

        public MediaCoverImage(Json.Object jsonMediaTitle) {
            this.extraLarge = jsonMediaTitle.get_string_member("extraLarge");
            this.large = jsonMediaTitle.get_string_member("large");
            this.medium = jsonMediaTitle.get_string_member("medium");
        }
    }

    public class User : Object {
        public int id {get; private set;}
        public string name {get; private set;}
        public UserAvatar avatar {get; private set;}

        public User(Json.Object jsonUser) {
            this.id = (int)jsonUser.get_int_member("id");
            this.name = jsonUser.get_string_member("name");
            this.avatar = new UserAvatar(jsonUser.get_object_member("avatar"));
        }
    }

    public class UserAvatar : Object {
        public string large {get; private set;}
        public string medium {get; private set;}

        public UserAvatar(Json.Object jsonAvatar) {
            this.large = jsonAvatar.get_string_member("large");
            this.medium = jsonAvatar.get_string_member("medium");
        }
    }

    public enum MediaType {
        ANIME,
        MANGA;

        public string to_string() {
            switch(this) {
            case ANIME:
                return "ANIME";
            case MANGA:
                return "MANGA";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }

        public static MediaType? from_string(string? media_type_str) {
            if(media_type_str == null)
                return null;

            switch(media_type_str.up()) {
            case "ANIME":
                return ANIME;
            case "MANGA":
                return MANGA;
            }

            return null;
        }

        public string to_human_string() {
            switch(this) {
            case ANIME:
                return "Anime";
            case MANGA:
                return "Manga";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }
    }

    public enum MediaFormat {
        TV,
        TV_SHORT,
        MOVIE,
        SPECIAL,
        OVA,
        ONA,
        MUSIC,
        MANGA,
        NOVEL,
        ONE_SHOT;

        public string to_string() {
            switch(this) {
            case TV:
                return "TV";
            case TV_SHORT:
                return "TV_SHORT";
            case MOVIE:
                return "MOVIE";
            case SPECIAL:
                return "SPECIAL";
            case OVA:
                return "OVA";
            case ONA:
                return "ONA";
            case MUSIC:
                return "MUSIC";
            case MANGA:
                return "MANGA";
            case NOVEL:
                return "NOVEL";
            case ONE_SHOT:
                return "ONE_SHOT";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }

        public static MediaFormat? from_string(string? media_format_str) {
            if(media_format_str == null)
                return null;

            switch(media_format_str.up()) {
            case "TV":
                return TV;
            case "TV_SHORT":
                return TV_SHORT;
            case "MOVIE":
                return MOVIE;
            case "SPECIAL":
                return SPECIAL;
            case "OVA":
                return OVA;
            case "ONA":
                return ONA;
            case "MUSIC":
                return MUSIC;
            case "MANGA":
                return MANGA;
            case "NOVEL":
                return NOVEL;
            case "ONE_SHOT":
                return ONE_SHOT;
            }

            return null;
        }

        public string to_human_string() {
            switch(this) {
            case TV:
                return "TV";
            case TV_SHORT:
                return "TV Short";
            case MOVIE:
                return "Movie";
            case SPECIAL:
                return "Special";
            case OVA:
                return "OVA";
            case ONA:
                return "ONA";
            case MUSIC:
                return "Music";
            case MANGA:
                return "Manga";
            case NOVEL:
                return "Novel";
            case ONE_SHOT:
                return "Oneshot";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }
    }

    public enum MediaStatus {
        FINISHED,
        RELEASING,
        NOT_YET_RELEASED,
        CANCELLED,
        HIATUS;
        
        public string to_string() {
            switch(this) {
            case FINISHED:
                return "FINISHED";
            case RELEASING:
                return "RELEASING";
            case NOT_YET_RELEASED:
                return "NOT_YET_RELEASED";
            case CANCELLED:
                return "CANCELLED";
            case HIATUS:
                return "HIATUS";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }

        public static MediaStatus? from_string(string? media_status_str) {
            if(media_status_str == null)
                return null;

            switch(media_status_str.up()) {
            case "FINISHED":
                return FINISHED;
            case "RELEASING":
                return RELEASING;
            case "NOT_YET_RELEASED":
                return NOT_YET_RELEASED;
            case "CANCELLED":
                return CANCELLED;
            case "HIATUS":
                return HIATUS;
            }

            return null;
        }

        public string to_human_string() {
            switch(this) {
            case FINISHED:
                return "Finished";
            case RELEASING:
                return "Releasing";
            case NOT_YET_RELEASED:
                return "Not Yet Released";
            case CANCELLED:
                return "Cancelled";
            case HIATUS:
                return "On Hiatus";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }
    }

    public enum MediaListEntryStatus {
        CURRENT,
        PLANNING,
        COMPLETED,
        DROPPED,
        PAUSED,
        REPEATING;

        public string to_string() {
            switch(this) {
            case CURRENT:
                return "CURRENT";
            case PLANNING:
                return "PLANNING";
            case COMPLETED:
                return "COMPLETED";
            case DROPPED:
                return "DROPPED";
            case PAUSED:
                return "PAUSED";
            case REPEATING:
                return "REPEATING";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }

        public static MediaListEntryStatus? from_string(string? media_list_entry_status_str) {
            if(media_list_entry_status_str == null)
                return null;

            switch(media_list_entry_status_str.up()) {
            case "CURRENT":
                return CURRENT;
            case "PLANNING":
                return PLANNING;
            case "COMPLETED":
                return COMPLETED;
            case "DROPPED":
                return DROPPED;
            case "PAUSED":
                return PAUSED;
            case "REPEATING":
                return REPEATING;
            }

            return null;
        }

        public string to_human_string() {
            switch(this) {
            case CURRENT:
                return "Current";
            case PLANNING:
                return "Planning";
            case COMPLETED:
                return "Completed";
            case DROPPED:
                return "Dropped";
            case PAUSED:
                return "Paused";
            case REPEATING:
                return "Repeating";
            }

            // This shouldn't be reachable, but I had to add it so the compiler doesn't complain.
            return "";
        }
    }
}

