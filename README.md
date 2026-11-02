# Notch — Call and Put Options

> Notch trades call and put options natively: writers post collateral into a vault, buyers pay premium and choose strike plus expiry, and the settlement window exercises price paths with per-lot granularity.

## What it does

Notch trades call and put options natively: writers post collateral into a vault, buyers pay premium and choose strike plus expiry, and the settlement window exercises price paths with per-lot granularity. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/OptionsProtocol.sol` |
| Contract name | `OptionsProtocol` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 6 (of which 2 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `createOption` | payable | uint256 |
| `buyOption` | payable | tx receipt |
| `exerciseOption` | write | result / revert |
| `expireOption` | write | result / revert |
| `getOption` | view | address writer, address buyer, address underlying, uint256 strike, uint256 expiry, uint8 optType, uint256 premium, bool active, bool exercised |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `OptionCreated` | (uint256 indexed oid, address indexed writer, address indexed buyer, address underlying, uint256 strike, uint256 expiry, uint8 optType) |
| `OptionExercised` | (uint256 indexed oid, address indexed buyer, uint256 payout) |
| `OptionExpired` | (uint256 indexed oid, address indexed writer) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/options-protocol.git
cd options-protocol
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.