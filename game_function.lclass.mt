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


// A ligher implementation of classes that 
// uses dynamic binding to reduce copies of objects.

@:lclass = ::<= {

    @:applyClass ::(class, priv, obj) {
        if (class.inherits != empty) ::<= {
            foreach(class.inherits) ::(i, v) {
                applyClass(class:v, priv, obj);
            }
        }
        
        foreach(class.interface) ::(name, fn) {
            obj[name] = fn;
        }
    }
    
    @:construct ::(class, priv, obj, args) {
        if (class.inherits != empty) ::<= {
            foreach(class.inherits) ::(i, v) {
                construct(class:v, priv, obj, args);
            }
        }
        if (class.constructor != empty) ::<= {
            obj->setIsInterface(enabled:false);
            obj.constructor = class.constructor;
            obj->setIsInterface(enabled:true, private:priv);
            breakpoint();
            obj.constructor(*args);
        }
    
    }
    


    return ::(name => String, statics, inherits, constructor, interface) {

        @:type = if (inherits == empty)
            Object.newType(name)
        else 
            Object.newType(name, inherits:[...inherits]->map(to:::(value) <- value.type));

        @:class = {};
        if (statics != empty) ::<= {
            foreach(statics) ::(name => String, thing) {
                class[name] = thing;
            }
        }
        
        class.type = type;
        class.interface = interface;
        class.constructor = constructor;
        class.inherits = inherits;
        class.new = ::(*args) {
            @:obj = Object.instantiate(type);
            @:priv = {this:obj};
            applyClass(class, priv, obj);        
            obj.constructor = constructor;
            obj->setIsInterface(enabled:true, private:priv);
            construct(class, obj, priv, args);        
            return obj;
        }
        return class;
    }
}

