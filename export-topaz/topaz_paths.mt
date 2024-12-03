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
