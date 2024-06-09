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
@:paths = import(module:'sys_path.mt');
return ::<= {



    @:dump ::{
        return paths.enter(::{
            @:settingsAsset = Topaz.Resources.createDataAssetFromPath(
                path:'settings'
            );
            when (settingsAsset == empty) {};
            @:data = settingsAsset.getAsString();
            Topaz.Resources.removeAsset(:settingsAsset);
            when(data == '') {};
            return import(:'Matte.Core.JSON').decode(:data);
        });
    }
    
    
    @:save ::(object) {
        return paths.enter(::{
            @:str = import(:'Matte.Core.JSON').encode(:object);
            @:settingsAsset = Topaz.Resources.createAsset(
                name:'settings',
                type:Topaz.Asset.Type.Data
            );
            settingsAsset.setFromString(string:str);
            Topaz.Resources.writeAsset(
                asset: settingsAsset,
                fileType: '',
                outputPath: 'settings'
            );
            Topaz.Resources.removeAsset(:settingsAsset);
        });
    }


    return {
        set::(props) {
            @:dumped = dump();
            foreach(props) ::(k, v) {
                dumped[k] = v;
            }
            save(:dumped);
        },
        
        getObject:: {
            return dump();
        }
    }
};
