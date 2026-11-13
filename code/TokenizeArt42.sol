// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title TokenizeArt42
 * @author nbarbosa (42 Mulhouse)
 * @notice ERC-721 NFT contract supporting both decentralized IPFS metadata
 *         and 100% On-Chain Base64 SVG inscriptions via chunked SSTORE2 storage.
 */
contract TokenizeArt42 is ERC721URIStorage, Ownable {
    // Auto-incrementing counter tracking minted token IDs (starts at 1)
    uint256 private _nextTokenId;

    // Ordered list of SSTORE2 data contracts holding the raw SVG bytes
    address[] private _svgPointers;

    // Tracks which token IDs use dynamic on-chain Base64 metadata
    mapping(uint256 => bool) private _isOnChain;

    // Event emitted whenever a new NFT is minted (IPFS or On-Chain)
    event NFTMinted(address indexed minter, uint256 indexed tokenId, bool isOnChain);

    /**
     * @notice Initializes the ERC-721 collection name, symbol, and contract owner.
     */
    constructor() ERC721("42 Mulhouse - City Edition", "ART42") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    /**
     * @notice Appends an SSTORE2 data contract chunk containing raw on-chain SVG bytes.
     * @param pointer Address of the deployed SSTORE2 bytecode storage contract.
     */
    function addSvgPointer(address pointer) external onlyOwner {
        require(pointer != address(0) && pointer.code.length > 1, "Invalid SSTORE2 pointer");
        _svgPointers.push(pointer);
    }

    /**
     * @notice Mandatory part: Mints an NFT pointing to an external IPFS metadata URI.
     * @param recipient Address that will receive the minted NFT.
     * @param metadataURI IPFS URI pointing to the JSON metadata.
     * @return tokenId The newly minted NFT identifier.
     */
    function mintIPFS(address recipient, string memory metadataURI)
        public
        onlyOwner
        returns (uint256)
    {
        require(recipient != address(0), "Cannot mint to zero address");
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit NFTMinted(recipient, tokenId, false);
        return tokenId;
    }

    /**
     * @notice Bonus part: Mints a fully On-Chain NFT with embedded SVG artwork and JSON metadata.
     * @return tokenId The newly minted NFT identifier.
     */
    function mintOnChain() public returns (uint256) {
        require(_svgPointers.length > 0, "On-chain SVG artwork not initialized");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(msg.sender, tokenId);
        _isOnChain[tokenId] = true;

        emit NFTMinted(msg.sender, tokenId, true);
        return tokenId;
    }

    /**
     * @notice Returns the metadata URI for a given token (IPFS URI or On-Chain Base64 JSON).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        if (_isOnChain[tokenId]) {
            return _buildOnChainTokenURI();
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Returns the total number of NFTs minted so far.
     */
    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @dev Reassembles the raw SVG bytes from all SSTORE2 data contracts via EXTCODECOPY.
     */
    function _readSvgData() internal view returns (bytes memory data) {
        uint256 count = _svgPointers.length;
        require(count > 0, "SVG data pointers empty");

        uint256 totalSize = 0;
        for (uint256 i = 0; i < count; i++) {
            address ptr = _svgPointers[i];
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(ptr)
            }
            require(codeSize > 1, "Empty SSTORE2 pointer");
            totalSize += (codeSize - 1);
        }

        data = new bytes(totalSize);
        uint256 offset = 0x20;
        for (uint256 i = 0; i < count; i++) {
            address ptr = _svgPointers[i];
            uint256 chunkSize;
            assembly {
                chunkSize := sub(extcodesize(ptr), 1)
                extcodecopy(ptr, add(data, offset), 1, chunkSize)
            }
            offset += chunkSize;
        }
    }

    /**
     * @dev Encodes the on-chain SVG image and JSON metadata into a Base64 data URI.
     */
    function _buildOnChainTokenURI() internal view returns (string memory) {
        string memory imageURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(_readSvgData()))
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "42 Mulhouse - City Edition",',
                '"description": "Official TokenizeArt NFT representing 42 Mulhouse (Temple Saint-Etienne & Tour de l\'Europe), created by nbarbosa.",',
                '"artist": "nbarbosa",',
                '"image": "', imageURI, '",',
                '"attributes": [',
                '{"trait_type": "Artist", "value": "nbarbosa"},',
                '{"trait_type": "Campus", "value": "42 Mulhouse"},',
                '{"trait_type": "Monuments", "value": "Tour de l\'Europe & Temple Saint-Etienne"}',
                ']}'
            )
        );

        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json)))
        );
    }
}
