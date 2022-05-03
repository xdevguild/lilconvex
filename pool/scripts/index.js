import { ProxyNetworkProvider } from "@elrondnetwork/erdjs-network-providers";
import {
  Account,
  Address,
  TokenPayment,
  ContractFunction,
  SmartContract,
  BigUIntValue,
  Interaction,
} from "@elrondnetwork/erdjs";
import { UserSecretKey, UserSigner } from "@elrondnetwork/erdjs-walletcore";
import { path } from "path";

const setup = async () => {
  let networkProvider = new ProxyNetworkProvider(
    "https://testnet-gateway.elrond.com"
  );

  let addressOfBob = new Address(
    "erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5"
  );
  let bob = new Account(addressOfBob);
  let bobOnNetwork = await networkProvider.getAccount(addressOfBob);
  bob.update(bobOnNetwork);

  console.log(`I got ${bob.balance.toString() / 1e18} xEGLD`);

  return [addressOfBob, bob];
};

const main = async () => {
  let networkProvider = new ProxyNetworkProvider(
    "https://testnet-gateway.elrond.com"
  );
  let { addressOfBob, bob } = setup();

  let firstPayment = TokenPayment.fungibleFromAmount("USDC-780dd8", "1", 6);
  let secondPayment = TokenPayment.fungibleFromAmount("USDT-7d8186", "1", 6);
  let payments = [firstPayment, secondPayment];
  console.log(
    `Adding ${firstPayment.toPrettyString()} and ${secondPayment.toPrettyString()} to the pool`
  );

  let contract = new SmartContract({
    address: new Address(
      "erd1qqqqqqqqqqqqqpgqaphkarlvclh2c3v0hq2em73gcuxkh5yxj9ts6s5dt2"
    ),
  });
  let dummyFunction = new ContractFunction("addLiquidity");
  let args = [new BigUIntValue(1), new BigUIntValue(1)];

  let tx = new Interaction(contract, dummyFunction, args)
    .withNonce(60)
    .withMultiESDTNFTTransfer(payments)
    .withGasLimit(20000000)
    .withChainID("T")
    .buildTransaction();

  const readTestWalletFileContents = async (name) => {
    let filePath = path.join("Users", "quentin", "Elrond", "pems", name);
    return await fs.promises.readFile(filePath, { encoding: "utf8" });
  };

  let pemContents = await readTestWalletFileContents("yum0e1.pem");
  UserSecretKey.fromPem(pemContents).hex();

  let signer = new UserSigner(UserSecretKey.fromString(secretkeyHex));
  signer.sign(tx);
  console.log(tx);
  // await networkProvider.sendTransaction(tx);
};

main();
