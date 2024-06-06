
# Add Interaction Template

We encourage you to add new interaction types. 
Here's a template of json file, defining an interaction type (placed in the `interactions/` folder)

```json
{
    "chainId": 1,
    "txTo": "0x...",
    "functionSelector": "0xabab",
    "extra": {
        "title": "...",
        "description": "...",
        "avatarUrl": "..."
    }
}
```

## `chainId` 
Chain ID of the interaction. This field is saved in the InteractionRegistry contract directly.

## `txTo`
Target address of the interaction. This field is saved in the InteractionRegistry contract directly.

## `functionSelector`
4 bytes of the function selector of the target address. This field is saved in the InteractionRegistry contract directly.

## `extra`
Extra information. Following saved in the ipfs file and used as a NFT metadata in the InteractionFactory contract.

### `title`
Title of the interaction.

### `description`
Description of the interaction.

### `avatarUrl` 
Avatar of the target protocol. 
