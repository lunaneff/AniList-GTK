/* AnilistGtkApp.vala
 *
 * Copyright 2021 Laurin Neff
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
 */

namespace AnilistGtk {
    public class AnilistGtkApp : Gtk.Application {
        protected override void activate() {
            add_actions();

            var win = active_window;
            if(win == null) {
                win = new MainWindow(this);
            }
            win.present();
        }

        protected void add_actions() {
            var quit_action = new SimpleAction("quit", null);
            quit_action.activate.connect(() => {
                active_window.destroy();
            });
            set_accels_for_action("app.quit", {"<Control>q", "<Control>w"});
            add_action(quit_action);

            var about_action = new SimpleAction("about", null);
            about_action.activate.connect(() => {
                var dialog = new Gtk.AboutDialog() {
                    program_name = _("AniList-GTK"),
                    logo_icon_name = "anilist-gtk",
                    authors = { "Laurin Neff" },
                    license_type = Gtk.License.GPL_3_0,
                    copyright = "© 2021 Laurin Neff",
                    modal = true,
                    transient_for = active_window,
                };
                dialog.present();
            });
            add_action(about_action);

            var accels_action = new SimpleAction("accels", null);
            accels_action.activate.connect(() => {
                message("show accels window");
            });
            set_accels_for_action("app.accels", {"F1", "<Control>question"});
            add_action(accels_action);

            var settings_action = new SimpleAction("settings", null);
            settings_action.activate.connect(() => {
                message("show settings window");
            });
            set_accels_for_action("app.settings", {"<Control>comma"});
            add_action(settings_action);
        }

        public static int main(string[] args) {
            return new AnilistGtkApp().run(args);
        }
    }
}

