functor
import
    Browser
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define

    %% STUDENT START:
    
    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED

    % Returns transition Hash
    fun {TransactionHash Nonce Sender Receiver Value}
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
        end
    in 
        if Value == 0 then 1 % 0 has 1 digit so effort = 2^0 = 1
        else {Loop Value 0} end
    end


    % Initial state of blockchain from the genesis record
    % Each balance is converted into a user record with a nonce=0
    % Function written with help of AI
    fun {InitialState Genesis}
        {Record.map Genesis fun {$ Balance} user(balance: Balance nonce:0)end}
    end

    % Check if a transaction is valid
    fun {IsTransactionValid Transaction State}
        Sender = {GetUser State Transaction.sender}
    in
        if Transaction.value < 0 then 
            false
        else
            local Effort in
                Effort = {ComputeEffort Transaction.value}
                if Transaction.nonce \= Sender.nonce +1 then false
                elseif Transaction.hash \= {TransactionHash Transaction.nonce Transaction.sender Transaction.receiver Transaction.value} then false
                elseif Sender.balance < Transaction.value + Effort then false
                elseif Transaction.max_effort =< 0 then false 
                elseif Transaction.max_effort < Effort then false 
                else 
                    true
                end
            end
        end
    end

    % Makes a transaction and updates the state
    fun {MakeTransaction Transaction State}  
        Sender = {GetUser State Transaction.sender}
        Receiver = {GetUser State Transaction.receiver}
        Effort = {ComputeEffort Transaction.value}
        NewSender    = user(balance:Sender.balance-(Transaction.value+Effort)  nonce:Sender.nonce + 1)
        NewReceiver  = user(balance:Receiver.balance + Transaction.value  nonce:Receiver.nonce)

        StateSender= {Adjoin State {List.toRecord state [Transaction.sender#NewSender]}}
        StateReceiver = {Adjoin StateSender {List.toRecord state [Transaction.receiver#NewReceiver]}}
    in
        StateReceiver
    end

    % Returns an user if he exists, else creates him then returns him
    fun {GetUser State User}
        if {HasFeature State User} then State.User
        else user(balance:0 nonce:0)
        end
    end

    % Filter transactions of a block, updates state after each valid transaction
    fun {FilterBlockTransactions Transactions State TotalEffort Denylist Counts}
        case Transactions of nil then 
            result(transactions:nil state:State denylist:Denylist)
        [] H|T then
            local
                Sender = H.sender
                NewCounts = {IncrementSenderCount Counts Sender}
                SenderCount = {GetSenderCount NewCounts Sender}
            in
                %% Already denied users are ignored
                if {IsInList Sender Denylist} then
                    {FilterBlockTransactions T State TotalEffort Denylist NewCounts}

                %% The third transaction triggers denylisting and is ignored
                elseif SenderCount >= 3 then
                    local NewDenylist in
                        NewDenylist = {AddToDenylist Sender Denylist}

                        %% Debug
                        {Browser.browse deniedUser#Sender}
                        {Browser.browse denylist#NewDenylist}

                        {FilterBlockTransactions T State TotalEffort NewDenylist NewCounts}
                    end
                else
                    if {IsTransactionValid H State} then
                        local 
                            Effort = {ComputeEffort H.value}
                        in
                            if TotalEffort + Effort > 300 then
                                {FilterBlockTransactions T State TotalEffort Denylist NewCounts}
                            else
                                local 
                                NewState = {MakeTransaction H State}
                                Rest = {FilterBlockTransactions T NewState (TotalEffort + Effort) Denylist NewCounts}
                                in 
                                result(transactions:H|Rest.transactions state:Rest.state denylist:Rest.denylist)
                                end
                            end
                        end
                    else 
                        {FilterBlockTransactions T State TotalEffort Denylist NewCounts}
                    end
                end
            end
        end
    end

    % Gets all transactions with the same block number
    fun {GetBlockTransactions Transactions BlockNumber}
        case Transactions of nil then nil
        [] H|T then
            if H.block_number == BlockNumber then H|{GetBlockTransactions T BlockNumber}
            else nil
            end
        end
    end

    % Skips all transactions with the same block number and returns the rest for next block
    fun {SkipBlockTransactions Transactions BlockNumber}
        case Transactions of nil then nil
        [] H|T then
            if H.block_number == BlockNumber then {SkipBlockTransactions T BlockNumber}
            else Transactions
            end
        end
    end

    % Append block to blockchain
    fun {AppendBlock Blockchain NewBlock}
        case Blockchain of nil then [NewBlock]
        [] H|T then H|{AppendBlock T NewBlock}
        end
    end

    % Takes all transactions, groups them by block (creating the blocks) and append to blockchain
    fun {AppendToBlockchain Transactions State PreviousHash Blockchain Denylist}
        case Transactions of nil then
            result(blockchain:Blockchain state:State)
        [] H|_ then
            local
                BlockNumber = H.block_number
                BlockTransactions = {GetBlockTransactions Transactions BlockNumber}
                RestTransactions = {SkipBlockTransactions Transactions BlockNumber}
                FilterResult = {FilterBlockTransactions BlockTransactions State 0 Denylist counts()}
                ValidTransactions = FilterResult.transactions
                NewState = FilterResult.state
                NewDenylist = FilterResult.denylist
            in
                if ValidTransactions == nil then
                    {AppendToBlockchain RestTransactions NewState PreviousHash Blockchain NewDenylist}
                else
                    local 
                        NewBlock = block(
                            number:BlockNumber
                            previousHash:PreviousHash
                            transactions:ValidTransactions
                            hash:{BlockHash BlockNumber PreviousHash ValidTransactions}
                        )
                    in
                        {AppendToBlockchain RestTransactions NewState NewBlock.hash {AppendBlock Blockchain NewBlock} NewDenylist}
                    end
                end
            end
        end
    end
 
    %% STUDENT START:

    %% Return the decoded secret message
    fun {Decode Blockchain}
        {DecodeAcc Blockchain ""}
    end

    %% Decode each block and accumulate the resulting message
    fun {DecodeAcc Blockchain Acc}
        case Blockchain of nil then Acc
        [] H|T then
            local Hash DecodedHash NewAcc in
                Hash = H.hash
                DecodedHash = {DecodeHash Hash}
                NewAcc = {Append Acc DecodedHash}
                
                {DecodeAcc T NewAcc}
            end
        end
    end

    %% Convert the hash to a string before decoding it
    fun {DecodeHash Hash}
        DigitsString = {Int.toString Hash}
    in
        {DecodeHashAcc DigitsString ""}
    end

    %% Decode each pair of digits and append the matching character
    fun {DecodeHashAcc Digits Acc}
        case Digits of D1|D2|Rest then
            local Pair ModNumber Number Letter NewAcc in
                Pair = {String.toInt [D1 D2]}
                ModNumber = Pair mod 37

                if ModNumber < 10 then
                    Number = 36
                else
                    Number = ModNumber
                end

                Letter = {DecodeNumberPair Number}
                NewAcc = {Append Acc Letter}

                {DecodeHashAcc Rest NewAcc}
            end
        else
            Acc
        end
    end

    %% Map a decoded number to its Sharelock character
    fun {DecodeNumberPair Number}
        if Number >= 10 andthen Number =< 35 then
            [{List.nth "abcdefghijklmnopqrstuvwxyz" (Number - 9)}]
        elseif Number == 36 then
            " "
        else
            ""
        end
    end

    %% STUDENT END

    %%% =================== EXTENSIONS =================== 

    %% 1. DENYLIST

    %% Check if a user is in the denylist
    fun {IsInList User List}
        case List of nil then false
        [] H|T then
            if User == H then 
                true
            else 
                {IsInList User T}
            end
        end
    end

    %% Add a user to the denylist if not already present
    fun {AddToDenylist User Denylist}
        if {IsInList User Denylist} then 
            Denylist
        else 
            User|Denylist 
        end
    end

    %% Return the number of transactions already sent by a user in the current block
    fun {GetSenderCount Counts Sender}
        if {HasFeature Counts Sender} then
            Counts.Sender
        else
            0
        end
    end

    %% Increment the transaction count of a sender in the current block
    fun {IncrementSenderCount Counts Sender}
        NewCount = {GetSenderCount Counts Sender} + 1
    in
        {Adjoin Counts {List.toRecord counts [Sender#NewCount]}}
    end

    % This function is the starting point of the execution
    % The GenesisState and the Transactions are given as input and the function is expected to bound the FinalState and the FinalBlockchain to their respective final values.
    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        %% TODO
        State = {InitialState GenesisState}
        Result = {AppendToBlockchain Transactions State 0 nil nil}
    in
        FinalState = Result.state
        FinalBlockchain = Result.blockchain
        %% STUDENT END
    end
end