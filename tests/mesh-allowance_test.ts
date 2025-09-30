import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Mesh Allowance: Set initial allowance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('mesh-allowance', 'set-allowance', 
                [types.principal(wallet1.address), types.uint(1000)], 
                deployer.address
            )
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Mesh Allowance: Spend from allowance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('mesh-allowance', 'set-allowance', 
                [types.principal(wallet1.address), types.uint(1000)], 
                deployer.address
            ),
            Tx.contractCall('mesh-allowance', 'spend-allowance', 
                [
                    types.principal(deployer.address), 
                    types.uint(250), 
                    types.utf8("Test transaction")
                ], 
                wallet1.address
            )
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Mesh Allowance: Prevent overspending",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('mesh-allowance', 'set-allowance', 
                [types.principal(wallet1.address), types.uint(500)], 
                deployer.address
            ),
            Tx.contractCall('mesh-allowance', 'spend-allowance', 
                [
                    types.principal(deployer.address), 
                    types.uint(600), 
                    types.utf8("Overspend attempt")
                ], 
                wallet1.address
            )
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectErr().expectUint(2002); // ERR-INSUFFICIENT-FUNDS
    }
});