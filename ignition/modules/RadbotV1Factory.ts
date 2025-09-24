import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("RadbotV1FactoryModule", (m) => {
  // 1. Deploy the StringHelper library
  const stringHelper = m.library("StringHelper");

  // 2. Deploy RadbotV1Factory with the library linked
  const v1Factory = m.contract("RadbotV1Factory", [], {
    libraries: {
      StringHelper: stringHelper,
    },
  });

  return { v1Factory };
});
