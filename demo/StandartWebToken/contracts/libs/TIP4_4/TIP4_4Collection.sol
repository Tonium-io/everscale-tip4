/// We recommend using the compiler version 0.58.1. 
/// You can use other versions, but we do not guarantee compatibility of the compiler version.
pragma ton-solidity = 0.58.1;


pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;


import '../TIP6/TIP6.sol';
import './interfaces/ITIP4_4Collection.sol';
import '../TIP4_1/TIP4_1Collection.sol';
import 'TIP4_4Storage.sol';

/// @title One of the required contracts of an TIP4-1(Non-Fungible Token Standard) compliant technology.
/// You can read more about the technology here (https://github.com/nftalliance/docs/blob/main/src/Standard/TIP-4/1.md)
/// For detect what interfaces a smart contract implements used TIP-6.1 standard. ...
/// ... Read more here (https://github.com/nftalliance/docs/blob/main/src/Standard/TIP-6/1.md)
abstract contract TIP4_4Collection is TIP4_1Collection, ITIP4_4Collection {
    
    /// Code of the TIP4_1Nft conract or of the custom Nft contract based on the TIP4_1Nft
    TvmCell _codeStorage;
    uint128 _storageDeployValue = 0.5 ever;
    constructor(TvmCell codeStorage) public {
        tvm.accept();

        _codeStorage = codeStorage;
        
        _supportedInterfaces[ bytes4(tvm.functionId(ITIP6.supportsInterface)) ] = true;
        _supportedInterfaces[
            bytes4(tvm.functionId(ITIP4_4Collection.storageCode)) ^
            bytes4(tvm.functionId(ITIP4_4Collection.storageCodeHash)) ^
            bytes4(tvm.functionId(ITIP4_4Collection.resolveStorage))
        ] = true;
    }

    function storageCode() external override view responsible returns (TvmCell code) {
        return {value: 0, flag: 64, bounce: false} (_codeStorage);
    }
    function storageCodeHash() external override view responsible returns (uint256 codeHash){
        return {value: 0, flag: 64, bounce: false} (tvm.hash(_codeStorage));
    }

    function resolveStorage(address nft) external override view responsible returns (address storage) {
        TvmCell stateInit = tvm.buildStateInit({
            code : _codeStorage,
            varInit : {
                _nft : nft
            },
            contr : TIP4_4Storage
        });

        return {value: 0, flag: 64, bounce: false} (address(tvm.hash(stateInit)));         
    }

    function _deployStorage(
        uint256 uploader,
        string mimeType,
        uint32 chunksNum,
        address nft
    ) internal virtual returns(address newStorage) {
        newStorage = new TIP4_4Storage{
            code : _codeStorage,
            value : _storageDeployValue,
            varInit : {
                _nft : nft
            }
        } (
            uploader,
            mimeType,
            chunksNum
        );
    }
    function _buildNftState(
        TvmCell code,
        uint256 id
    ) internal virtual override pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: TIP4_4Nft,
            varInit: {_id: id},
            code: code
        });
    }

}