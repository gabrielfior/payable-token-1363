# payable-token-1363

## Possible extensions of this work

- BondingCurve:
    - Create abstract class BondingCurve, allowing for other bonding curves than only the linear one.
    - LinearBondingCurve extends BondingCurve

- ERC1363
    - Mint not really optimal, as we need the workaround of Ownable in the PoolToken contract.
    - A possibly better solution would be to have Pool inherit from ERC20 directly, allowing it to call `_mint` inside the `receive()` function.