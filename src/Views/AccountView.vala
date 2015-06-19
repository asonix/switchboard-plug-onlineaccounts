// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Pantheon Developers (http://launchpad.net/online-accounts-plug)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class OnlineAccounts.AccountView : Gtk.Grid {
    Gtk.Grid main_grid;
    OnlineAccounts.Account plugin;

    public AccountView (OnlineAccounts.Account plugin) {
        orientation = Gtk.Orientation.VERTICAL;
        this.plugin = plugin;
        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.margin = 12;
        main_grid.column_spacing = 6;
        main_grid.row_spacing = 6;

        string label_str = plugin.account.manager.get_provider (plugin.account.get_provider_name ()).get_display_name ();
        var name = plugin.account.get_display_name ();
        if (name != "" && name != null) {
            label_str = "%s - %s".printf (plugin.account.get_display_name (), label_str);
        }

        var user_label = new Gtk.Label (Markup.escape_text (label_str));
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, user_label);
        user_label.hexpand = true;

        var apps_label = new Gtk.Label ("");
        apps_label.set_markup ("<b>%s</b>".printf (Markup.escape_text (_("Content to synchronise:"))));
        ((Gtk.Misc) apps_label).xalign = 0;
        apps_label.margin_top = 12;

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_window.expand = true;

        var apps_grid = new Gtk.Grid ();
        apps_grid.margin_bottom = 12;
        apps_grid.margin_left = 12;
        apps_grid.margin_right = 12;
        apps_grid.column_spacing = 12;
        apps_grid.row_spacing = 6;

        int i = 1;
        var services = plugin.account.list_services ();
        foreach (var service in services) {
            var applications = new Ag.Manager ().list_applications_by_service (service);
            if (applications.length () == 0)
                continue;

            string i18n_domain = service.get_i18n_domain ();
            string tooltip = GLib.dgettext (i18n_domain, service.get_description ());

            var service_image = new Gtk.Image.from_icon_name (service.get_icon_name (), Gtk.IconSize.DIALOG);
            service_image.margin_left = 12;

            var service_label = new Gtk.Label ("");
            service_label.set_markup ("<big>%s</big>".printf (Markup.escape_text (GLib.dgettext (i18n_domain, service.get_display_name ()))));

            ((Gtk.Misc) service_label).xalign = 0;

            var service_switch = new Gtk.Switch ();
            service_switch.valign = Gtk.Align.CENTER;
            service_switch.tooltip_text = tooltip;
            plugin.account.select_service (service);
            service_switch.active = plugin.account.get_enabled ();
            service_switch.notify["active"].connect (() => {on_service_switch_activated (service_switch.active, service);});

            apps_grid.attach (service_image, 1, i, 1, 1);
            apps_grid.attach (service_label, 2, i, 1, 1);
            apps_grid.attach (service_switch, 3, i, 1, 1);
            i++;
        }

        if (i == 1) {
            var no_service_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var provider_name = plugin.account.manager.get_provider (plugin.account.get_provider_name ()).get_display_name ();
            var no_service_label = new Gtk.Label (_("There are no apps currently installed that link to your %s account").printf (provider_name));
            no_service_label.selectable = true;
            no_service_label.wrap = true;
            no_service_label.hexpand = true;
            no_service_label.justify = Gtk.Justification.CENTER;
            no_service_label.get_style_context ().add_class (Granite.StyleClass.H2_TEXT);
            var no_service_image = new Gtk.Image.from_icon_name ("applications-internet-symbolic", Gtk.IconSize.DIALOG);
            var no_service_grid = new Gtk.Grid ();
            no_service_grid.orientation = Gtk.Orientation.VERTICAL;
            no_service_grid.row_spacing = 6;
            no_service_grid.add (no_service_image);
            no_service_grid.add (no_service_label);
            no_service_box.set_center_widget (no_service_grid);
            no_service_box.expand = true;
            this.add (no_service_box);
        } else {
            var fake_grid_l = new Gtk.Grid ();
            fake_grid_l.hexpand = true;
            var fake_grid_r = new Gtk.Grid ();
            fake_grid_r.hexpand = true;
            apps_grid.attach (fake_grid_l, 0, 0, 1, 1);
            apps_grid.attach (fake_grid_r, 4, 0, 1, 1);

            scrolled_window.add_with_viewport (apps_grid);
            main_grid.add (user_label);
            this.add (main_grid);
            this.add (scrolled_window);
            apps_grid.attach (apps_label, 1, 0, 2, 1);
        }

        plugin.account.select_service (null);
    }

    private void on_service_switch_activated (bool enabled, Ag.Service service) {
        plugin.account.select_service (service);
        plugin.account.set_enabled (enabled);
        plugin.account.store_async.begin (null);
        plugin.account.select_service (null);
    }
    
}
