import "forge-std/src/Script.sol";

import {InteractionDataset} from "../src/InteractionDataset.sol";
import {InteractionRegistry} from "../src/InteractionRegistry.sol";
import {InteractionFactory} from "../src/InteractionFactory.sol";
import {_Proxy} from "../src/misc/Proxy.sol";

contract DeployAll is Script {
    string constant filename = "deployments.txt";

    function setUp() public {
        if (block.chainid == 31337) {
            // vm.writeLine(filename, "deploying to local network (foundry)");
        } else if (block.chainid == 80002) {
            // ok
        } else {
            revert("wrong chainid");
        }
    }

    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PK"));
        address initialManager = vm.envAddress("INITIAL_MANAGER");

        address interactionDataset = address(new InteractionDataset(initialManager));
        address interactionRegistry = address(new InteractionRegistry(initialManager));

        address interactionFactoryImpl = address(new InteractionFactory());
        address interactionFactoryProxy = address(
            new _Proxy(
                interactionFactoryImpl,
                initialManager,
                abi.encodeWithSelector(
                    InteractionFactory.initialize.selector,
                    initialManager
                )
            )
        );
    }
}
