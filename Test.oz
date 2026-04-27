functor
import
    Browser

define

    fun {Recu N}
        if N==0 then 
            0
        else 
            N + {Recu (N-1)} 
        end
    end

    {Browser.browse {Recu 10}}
end