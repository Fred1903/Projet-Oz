functor
import
    Open
    System
    Application
export
    readTransactionsFromFile:ReadTransactionsFromFile
    readGenesisFromFile:ReadGenesisFromFile
    writeLineInFile:WriteLineInFile
    writeLineLnInFile:WriteLineLnInFile
define 
    % Read a file with one transaction per line and 
    % return a list of transactions parsed as records
    fun {ReadTransactionsFromFile FilePath}
        % Recursively parse transactions from lines of fields separated by ',' 
        % to transactions records with the fields:
        % block_number, nonce, hash, sender, receiver, value and max_effort
        proc {ParseTransactionsRecursively Lines Transactions}
            % Append the Tx  at the end of the unbound list Transactions
            % and keep it unbound using the unbound Reste variable 
            proc {Append Transactions Tx Reste}
                Transactions = Tx|Reste
            end

            fun {ParseTransaction Fields}
                % Fields format: block_number,nonce,hash,sender,receiver,value,max_effort
                BlockNumber = Fields.1
                Nonce = Fields.2.1
                Hash = Fields.2.2.1
                Sender = Fields.2.2.2.1
                Receiver = Fields.2.2.2.2.1
                Value = Fields.2.2.2.2.2.1
                MaxEffort = Fields.2.2.2.2.2.2.1
            in
                if {Not {String.isInt BlockNumber}} then
                    ErrorMessage = "Value Error: '" # BlockNumber # "' is not a valid integer representation of a block number field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Nonce}} then
                    ErrorMessage = "Value Error: '" # Nonce # "' is not a valid integer representation of a nonce field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Hash}} then
                    ErrorMessage = "Value Error: '" # Hash # "' is not a valid integer representation of a hash field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Value}} then
                    ErrorMessage = "Value Error: '" # Value # "' is not a valid integer representation of a value field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Sender}} then
                    ErrorMessage = "Value Error: '" # Sender # "' is not a valid integer representation of a sender field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Receiver}} then
                    ErrorMessage = "Value Error: '" # Receiver # "' is not a valid integer representation of a receiver field. (Parse transactions)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                else
                    tx(
                        block_number:{StringToInt BlockNumber}
                        nonce:{StringToInt Nonce}
                        hash:{StringToInt Hash}
                        sender:{StringToInt Sender}
                        receiver:{StringToInt Receiver}
                        value:{StringToInt Value}
                        max_effort:{StringToInt MaxEffort}
                    )
                end
            end

        in
            case Lines of nil then
                Transactions = nil
            [] H|T then
                Tx = {ParseTransaction {String.tokens H &,}}
                Reste
            in
                {Append Transactions Tx Reste}
                {ParseTransactionsRecursively T Reste}
            end
        end

        F Content Lines
        Transactions
    in
        % Read all from file
        F={New Open.file init(name:FilePath flags:[read])}
        Content = {F read(list:$ size:all)}
        Lines = {String.tokens Content &\n}

        % List of transactions
        {ParseTransactionsRecursively Lines Transactions}
        {F close}

        Transactions
    end


    % Read a file and parse the genesis block as a record with the format:
    % genesis(address1:balance1 address2:balance2 ... addressN:balanceN)
    fun {ReadGenesisFromFile FilePath}
        % Parse a Genesis block from a list of "address,balance" strings
        % and return a record representing the genesis state with the format
        % genesis(address1:balance1 address2:balance2 ... addressN:balanceN)
        fun {ParseGenesis Lines}
            fun {ParseGenesisFields Fields}
                User = Fields.1
                Balance = Fields.2.1
            in
                if {Not {String.isInt User}} then
                    ErrorMessage = "Value Error: '" # User # "' is not a valid integer representation of a user field. (Parse genesis block)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                elseif {Not {String.isInt Balance}} then
                    ErrorMessage = "Value Error: '" # Balance # "' is not a valid integer representation of a balance field. (Parse genesis block)"
                in
                    {System.show {VirtualString.toAtom ErrorMessage}}
                    {System.show 'Exit application...'}
                    {Application.exit 1}
                else
                    {String.toInt User}#{String.toInt Balance}
                end
            end
            % Parse a Genesis list from a list of "address,balance" strings
            % and returns a list with the format:
            % [address1#balance1 address2#balance2 ... addressN#balanceN]
            fun {ParseGenesisListRecursively Lines GenesisList}
                case Lines of nil then GenesisList
                [] H|T then 
                    Fields = {String.tokens H &,}
                in
                    {ParseGenesisListRecursively T {ParseGenesisFields Fields}|GenesisList}
                end
            end

            GenesisList
        in
            GenesisList = {ParseGenesisListRecursively Lines nil}
            {List.toRecord genesis GenesisList}
        end

        F Content Lines

    in
        F={New Open.file init(name:FilePath flags:[read])}
        Content = {F read(list:$ size:all)}
        Lines = {String.tokens Content &\n}

        {ParseGenesis Lines}
    end
    
    proc {WriteLineInFile Sentence File}
        % File should be already open
        {File write(vs:Sentence)}
    end

    proc {WriteLineLnInFile Sentence File}
        % File should be already open
        {File write(vs:Sentence)}
        {File write(vs:"\n")}
    end
end