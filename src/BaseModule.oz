functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% STUDENT START:
    
    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED

    % Returns transition Hash
    fun {TransitionHash Nonce Sender Receiver Value}
         (Nonce + Sender + Receiver + Value) mod 1000000
    end

    % Returns sum of transition Hashes
    fun {SumTransactionsHashes Transactions}
        case Transactions of nil then 0
        [] H|T then H.hash + {SumTransactionsHashes T}
        end
    end

    % Returns block hash
    fun {BlockHash Number PreviousNumber Transactions}
        (Number + PreviousNumber + {SumTransactionsHashes Transactions}) mod 1000000
    end

    % Returns effort of a transaction
    % Ex: Effort for 500 (N=length=3)=Sum(2^0 to N-1)= 2^0 + 2^1 + 2^2 = 1+2+4=7
    % --> Sum = 2^n-1 --> 2^3-1 = 7 
    % Acc : Sum n+1= 2 * Sum n +1 
    fun {ComputeEffort Value}
        fun {Loop N Accumulator}
            if N==0 then Accumulator
            else {Loop N div 10 2*Accumulator+1}
        end
    in 
        {Loop Value 0}
    end

    
    %% STUDENT END
 
    %% Return a string representation of the secret
    fun {Decode Blockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
    end


    % ATTENTION; SUR FORUM YA MARQUÉ QUE FAUT REMPLACER FUN PAR PROC ICI
    % --> a VOIR QUAND ON IMPLÉMENTE

    % This function is the starting point of the execution
    % The GenesisState and the Transactions are given as input and the function is expected to bound the FinalState and the FinalBlockchain to their respective final values.
    fun {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
    end
end