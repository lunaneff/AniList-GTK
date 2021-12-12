/* DPAPI.c
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

#include "DPAPI.h"

static GBytes* dpapi_encrypt(GBytes* data) {
    DATA_BLOB in_data;
    DATA_BLOB out_data;

    in_data.pbData = g_bytes_get_data(data, &in_data.cbData);

    WINBOOL success = CryptProtectData(
        &in_data,
        NULL,
        NULL,
        NULL,
        NULL,
        0,
        &out_data
    );

    return g_bytes_new(out_data.pbData, out_data.cbData);
}

static GBytes* dpapi_decrypt(GBytes* data) {
    DATA_BLOB in_data;
    DATA_BLOB out_data;

    in_data.pbData = g_bytes_get_data(data, &in_data.cbData);

    WINBOOL success = CryptUnprotectData(
        &in_data,
        NULL,
        NULL,
        NULL,
        NULL,
        0,
        &out_data
    );

    return g_bytes_new(out_data.pbData, out_data.cbData);
}