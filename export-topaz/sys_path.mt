/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:Topaz = import(module:'Topaz');

return ::<= {
    @location_ = ".";

    @:enterLocation = ::(action) {
        @:oldPath = Topaz.Resources.getPath();
        Topaz.Resources.setPath(path:location_);
        @ret;
        {:::} {
            ret = action();
        } : {
            onError ::(message) {
                Topaz.Resources.setPath(path:oldPath);            
                error(detail:message.detail);
            }
        }
        Topaz.Resources.setPath(path:oldPath);
        return ret;
    }

    return {
        enter::(action) <- enterLocation(:action),
        setMainPath::(location) {
            location_ = location;
        }
    };
}