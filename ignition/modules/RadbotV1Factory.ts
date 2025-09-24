import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("RadbotV1FactoryModule", (m) => {
  const v1Factory = m.contract("RadbotV1Factory");

  return { v1Factory };
});
