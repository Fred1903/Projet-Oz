functor
import
    Application
    System
    BaseModule at './src/BaseModule.ozf'
    FileHelper at './library/FileHelperModule.ozf'
define

    %% This function corresponds to the logic of building the blockchain from the genesis state and the transactions.
    %% It create blocks containing valid and filtered transactions, append them to the Blockchain and finally update the State.
    %% It then returns the FinalState and the FinalBlockchain as a tuple.
    fun {RunBlockchain GenesisState Transactions}
        FinalState FinalBlockchain        
    in
        {BaseModule.executeBlockchain GenesisState Transactions FinalState FinalBlockchain}  
        FinalState#FinalBlockchain
    end

    proc {Main}
        GenesisFilePath = './data/genesis.txt'
        TransactionsFilePath = './data/transactions.txt'

        GenesisState Transactions
        FinalState FinalBlockchain
    in
        % Retrieve genesis data and transactions
        try 
            GenesisState = {FileHelper.readGenesisFromFile GenesisFilePath} 
        catch Error then
                {System.showInfo "Error while trying to read genesis file: "}
                {System.show Error}
                {Application.exit 1}
        end
        try 
            Transactions = {FileHelper.readTransactionsFromFile TransactionsFilePath}
        catch Error then
                {System.showInfo "Error while trying to read transactions file: "}
                {System.show Error}
                {Application.exit 1}
        end
                
        % From the genesis state, process all transactions to generate the blockchain
        FinalState#FinalBlockchain = {RunBlockchain GenesisState Transactions}

        {System.showInfo "Final State:"}
        {System.show FinalState}
        {System.showInfo "Final Blockchain:"}
        {System.show FinalBlockchain}
        {System.showInfo "Secret is: "}
        {System.showInfo {BaseModule.decode FinalBlockchain}}
    end

    {Main}
end