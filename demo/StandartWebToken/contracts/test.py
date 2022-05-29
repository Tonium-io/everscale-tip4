from tonos_ts4 import ts4
import json

eq = ts4.eq


ts4.init('../build', verbose = True)

main_keypair = ts4.make_keypair()

codeNft = ts4.load_code_cell('Nft.tvc')
codeIndex = ts4.load_code_cell('Index.tvc')
codeIndexBasis = ts4.load_code_cell('IndexBasis.tvc')
codeStorage = ts4.load_code_cell('TIP4_4Storage.tvc')

ts4.register_abi("Index")
ts4.register_abi("IndexBasis")
ts4.register_abi("Nft")
ts4.register_abi("TIP4_4Storage")
ts4.register_abi("Collection")

collection = ts4.BaseContract('Collection',dict(
    codeNft=codeNft,
    codeIndex=codeIndex,
    codeIndexBasis=codeIndexBasis,
    codeStorage=codeStorage,
    ownerPubkey=main_keypair[1],
    json=json.dumps(dict()),
    mintingFee=int(1e9)
),keypair=main_keypair,balance=int(1e11))

wallet = ts4.BaseContract("SafeMultisigWallet", dict(
    owners=[main_keypair[1]],
    reqConfirms=1),keypair=main_keypair,balance=int(1e11))

payload = ts4.encode_message_body('Collection', 'mintNft', dict(
    json=json.dumps(dict(type="Basic Nft")),
    uploader = main_keypair[1],
    mimeType = "I dont know",
    chunksNum = 2))

wallet.call_method_signed("sendTransaction",dict(
    dest = collection.addr,
    value = int(1e10),
    bounce = True,
    flags = 0,
    payload = payload
))

ts4.dispatch_messages()
nftAddr = collection.call_getter("nftAddress",dict(id=0,answerId=0))

nft = ts4.BaseContract("Nft", dict(
    owner=wallet.addr,
    sendGasTo=wallet.addr,
    remainOnNft = 1,
    json = "",
    indexDeployValue = 1,
    indexDestroyValue = 1,
    codeIndex=codeIndex,
    storageAddr = wallet.addr
),address=nftAddr)

storageAddr = nft.call_getter("getStorage",dict(answerId=0))

storage = ts4.BaseContract("TIP4_4Storage", dict(
    uploaderPubkey = main_keypair[1],
    mimeType="",
    chunksNum=2
),address=storageAddr,keypair=main_keypair)

storage.call_method("fill",dict(
    id=0,
    chunk="0x1234",
    gasReceiver=wallet.addr),private_key=main_keypair[0])


storage.call_method("fill",dict(
    id=0,
    chunk="0x1234",
    gasReceiver=wallet.addr),private_key=main_keypair[0],expect_ec=103)

storage.call_method("fill",dict(
    id=1,
    chunk="0x1234",
    gasReceiver=wallet.addr),private_key=main_keypair[0])

ts4.dispatch_messages()

print(storage.call_getter("getInfo",dict(answerId=0)))