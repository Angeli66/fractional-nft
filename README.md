Fractional NFT
The Fractional NFT contract introduces shared ownership of NFTs by splitting one NFT into multiple fungible token shares.
It allows collective ownership, trading, and governance over a single high-value NFT asset — ideal for DAOs, collector groups, or DeFi ecosystems.
Built using Clarity, it ensures immutable, transparent, and secure fractionalization on the Stacks blockchain.

Features
Lock and fractionalize a single NFT into fungible shares
Trade or transfer fractional ownership tokens
Set and manage total supply of NFT shares
Enable buyout to reclaim the original NFT
Automatically distribute proceeds during redemption
Transparent tracking of NFT locking and share balances

Technical Overview
Language: Clarity
Purpose: Convert NFT ownership into divisible tokens for shared governance or liquidity
Use Cases: NFT DAOs, shared collectibles, art tokenization, and DeFi collateralization

Core Functions:
Function	-Description
lock-nft(token-id, nft-contract, total-fractions)	-Locks an NFT and mints fractional ownership tokens
transfer-fraction(recipient, amount)	-Transfers fractional tokens between holders
initiate-buyout(token-id, offer-amount)	-Starts a buyout proposal to reclaim full ownership
redeem-nft(token-id)	-Redeems full NFT when all fractional tokens are collected or buyout succeeds
get-fraction-info(token-id) -Retrieves fractional ownership details
