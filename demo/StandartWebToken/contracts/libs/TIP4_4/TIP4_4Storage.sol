pragma ton-solidity >= 0.58.0;
pragma AbiHeader time;
pragma AbiHeader expire;

import 'interfaces/ITIP4_4Storage.sol';
import 'TIP4_4Nft.sol';

contract TIP4_4Storage is ITIP4_4Storage {
    string _mimeType;
    address static _nft;
    address _collection;
    uint256 _uploaderPubkey;
    uint32 _chunksNums;
    uint32 _uploaded = 0;

    uint8 constant MAX_CLEANUP_MSGS = 30;

    mapping(uint => uint32) messages;

    mapping(uint32 => bytes) _content;

    constructor(
        uint256 uploaderPubkey,
        string mimeType,
        uint32 chunksNums
    ) public {
        require(tvm.pubkey() == 0, 101);
        tvm.accept();
        _collection = msg.sender;
        _mimeType = mimeType;
        _uploaderPubkey = uploaderPubkey;
        _chunksNums = chunksNums;

    }
    function fill(uint32 id, bytes chunk, address gasReceiver) override external {
        require(msg.pubkey() == _uploaderPubkey, 102);
        tvm.accept();
        gc();
        _content[id] = chunk;
        _uploaded ++;
        if (_uploaded == _chunksNums){
            TIP4_4Nft(_nft).onStorageFillComplete{value: 0, flag: 128 + 2}(gasReceiver);
        }

    }
    function getInfo() override external view responsible returns (
        address nft,
        address collection,
        string mimeType,
        mapping(uint32 => bytes) content
    ){
        return {value: 0, flag: 64, bounce: false} (_nft,_collection,_mimeType,_content);
    }

    function afterSignatureCheck(TvmSlice body, TvmCell message) private inline returns (TvmSlice) {
        // Via TvmSlice methods we read header fields from the message body

        body.decode(uint64); // The first 64 bits contain timestamp which is usually used to differentiate messages.
        uint32 expireAt = body.decode(uint32);

        require(expireAt >= now, 101);   // Check that message is not expired.

        // Runtime function tvm.hash() allows to calculate the hash of the message.
        uint hash = tvm.hash(message);

        // Check that the message is unique.
        require(!messages.exists(hash), 102);

        // Save the hash of the message in  the state variable.
        messages[hash] = expireAt;

        // After reading message headers this function must return the rest of the body slice.
        return body;
    }

    /// @notice Allows to delete expired messages from dict.
    function gc() private {
        optional(uint256, uint32) res = messages.min();
        uint8 counter = 0;
        while (res.hasValue() && counter < MAX_CLEANUP_MSGS) {
            (uint256 msgHash, uint32 expireAt) = res.get();
            if (expireAt < now) {
                delete messages[msgHash];
            }
            counter++;
            res = messages.next(msgHash);
        }
    }
}
