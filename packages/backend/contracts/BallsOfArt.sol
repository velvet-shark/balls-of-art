//SPDX-License-Identifier: MIT
// @title    Balls of Art
// @version  1.0.0
// @author   Radek Sienkiewicz | velvetshark.com
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract BallsOfArt is ERC721, Ownable {
    // Ball parameters
    struct Ball {
        uint x; // x coordinates of the top left corner
        uint y; // y coordinates of the top left corner
        uint width;
        uint height;
        string fill; // ball color
        uint randomBase;
    }

    uint constant maxSupply = 111; // max number of tokens
    uint public totalSupply = 0; // number of tokens minted
    uint public mintPrice = 0.005 ether;

    // Events
    event BallsCreated(uint indexed tokenId);

    constructor() ERC721("Balls of Art", "BART") {}

    // Functions
    function backgroundColors(uint index)
        internal
        pure
        returns (string memory)
    {
        string[7] memory bgColors = [
            "#ffffff",
            "#F1F1F1",
            "#EEF6FF",
            "#FCF8E8",
            "#EEF1FF",
            "#FFFDE3",
            "#2C3639"
        ];
        return bgColors[index];
    }

    function ballColors(uint index) internal pure returns (string memory) {
        string[33] memory bColors = [
            "#1eafed",
            "#25316D",
            "#325fa3",
            "#367E18",
            "#38e27d",
            "#400D51",
            "#5d67c1",
            "#7294d4",
            "#A1C298",
            "#CC3636",
            "#F07DEA",
            "#F637EC",
            "#FA7070",
            "#a74f6c",
            "#c2c2d0",
            "#cc0e74",
            "#e5c37a",
            "#e6a0c4",
            "#e8185d",
            "#4bbe9d",
            "#fb97b3",
            "#ff0000",
            "#000007",
            "#2A0944",
            "#3330E4",
            "#5bbcd6",
            "#74275c",
            "#8758FF",
            "#96ac92",
            "#9c65ca",
            "#D800A6",
            "#F57328",
            "#FECD70"
        ];
        return bColors[index];
    }

    function createBallStruct(
        uint x,
        uint y,
        uint width,
        uint height,
        uint randomBase
    ) internal pure returns (Ball memory) {
        return
            Ball({
                x: x,
                y: y,
                width: width,
                height: height,
                fill: ballColors(randomBase % 21), // Choose random color from backgroundColors array. TODO: Change to 50 (size of bgcolors array)
                randomBase: randomBase
            });
    }

    function ballSvg(Ball memory ball) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    uint2str(ball.x),
                    '" y="',
                    uint2str(ball.y),
                    '" width="',
                    uint2str(ball.width),
                    '" height="',
                    uint2str(ball.height),
                    '" fill="',
                    ball.fill,
                    '" rx="150" /> <path fill="none" stroke="#ffffff" stroke-width="20" stroke-linecap="round" d="M ',
                    uint2str(ball.x + ball.width - 150),
                    " ",
                    uint2str(ball.y + ball.height - 50),
                    " A 100 100 0 0 0 ",
                    uint2str(ball.x + ball.width - 50),
                    " ",
                    uint2str(ball.y + ball.height - 150),
                    '" />'
                )
            );
    }

    // Generate SVG code for a single line
    function generateLineSvg(uint lineNumber, uint randomBase)
        public
        view
        returns (string memory)
    {
        // Line SVG
        string memory lineSvg = "";

        uint y = 150; // Default y for row 1
        if (lineNumber == 2) {
            y = 475; // Default y for row 2
        } else if (lineNumber == 3) {
            y = 800; // Default y for row 3
        }

        // Size of ball at slot 1
        uint ballSize11 = drawBallSize(3, randomBase);

        // Ball size 1x? Paint 1x at slot 1
        if (ballSize11 == 1) {
            Ball memory ball11 = createBallStruct(150, y, 300, 300, randomBase);
            lineSvg = string.concat(lineSvg, ballSvg(ball11));

            // Slot 2
            // Size of ball at slot 2
            uint ballSize12 = drawBallSize(2, randomBase >> 2);

            // Ball size 1x? Paint 1x at slot 2 and 1x at slot 3
            if (ballSize12 == 1) {
                Ball memory ball12 = createBallStruct(
                    475,
                    y,
                    300,
                    300,
                    randomBase >> 4
                );
                Ball memory ball13 = createBallStruct(
                    800,
                    y,
                    300,
                    300,
                    randomBase >> 6
                );
                lineSvg = string.concat(
                    lineSvg,
                    ballSvg(ball12),
                    ballSvg(ball13)
                );

                // Ball size 2x? Paint 2x at slot 2
            } else if (ballSize12 == 2) {
                Ball memory ball12 = createBallStruct(
                    475,
                    y,
                    625,
                    300,
                    randomBase >> 8
                );
                lineSvg = string.concat(lineSvg, ballSvg(ball12));
            }

            // Ball size 2x? Paint 2x at slot 1 and 1x at slot 3
        } else if (ballSize11 == 2) {
            Ball memory ball11 = createBallStruct(
                150,
                y,
                625,
                300,
                randomBase >> 10
            );
            Ball memory ball13 = createBallStruct(
                800,
                y,
                300,
                300,
                randomBase >> 12
            );
            lineSvg = string.concat(lineSvg, ballSvg(ball11), ballSvg(ball13));

            // Ball size 3x? Paint 3x at slot 1
        } else if (ballSize11 == 3) {
            Ball memory ball11 = createBallStruct(
                150,
                y,
                950,
                300,
                randomBase >> 14
            );
            lineSvg = string.concat(lineSvg, ballSvg(ball11));
        }

        return lineSvg;
    }

    // Generate final SVG code for the NFT
    function generateFinalSvg() public view returns (string memory) {
        uint randomBase1 = uint(
            keccak256(abi.encodePacked(block.basefee, block.timestamp))
        );
        uint randomBase2 = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        uint randomBase3 = uint(
            keccak256(abi.encodePacked(msg.sender, block.timestamp))
        );

        bytes memory backgroundCode = abi.encodePacked(
            '<rect width="1250" height="1250" fill="',
            backgroundColors(randomBase1 % 7),
            '" />'
        );

        // Which line will contain the eyes
        uint eyesLocation = (randomBase1 % 3) + 1;

        // SVG opening and closing tags, background color + 3 lines generated
        string memory finalSvg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 1250 1250" xmlns="http://www.w3.org/2000/svg">',
                backgroundCode,
                generateLineSvg(1, randomBase1),
                generateLineSvg(2, randomBase2),
                generateLineSvg(3, randomBase3),
                drawEyes(eyesLocation),
                "</svg>"
            )
        );

        return finalSvg;
    }

    function drawEyes(uint eyesLocation) internal pure returns (string memory) {
        // Bottom-right location by default
        uint y1 = 930;
        uint y2 = 980;

        if (eyesLocation == 1) {
            y1 = 280;
            y2 = 330;
        } else if (eyesLocation == 2) {
            y1 = 605;
            y2 = 655;
        } // Location 3 skipped because it's set up as default already, and only changed if location is 1 or 2

        return
            string(
                abi.encodePacked(
                    '<rect x="980" y="',
                    uint2str(y1),
                    '" width="30" height="30" fill="#ffffff" rx="15"><animate attributeType="XML" attributeName="fill" values="#ffffff00;#ffffff00;#ffffff00;#ffffff00;#ffffff00;#ffffff;#ffffff00;#ffffff00;#ffffff00;#ffffff00;" dur="10s" repeatCount="indefinite"/></rect><rect x="930" y="',
                    uint2str(y2),
                    '" width="30" height="30" fill="#ffffff" rx="15"><animate attributeType="XML" attributeName="fill" values="#ffffff00;#ffffff00;#ffffff00;#ffffff00;#ffffff00;#ffffff;#ffffff00;#ffffff00;#ffffff00;#ffffff00;" dur="10s" repeatCount="indefinite"/></rect>'
                )
            );
    }

    function drawBallSize(uint maxSize, uint randomBase)
        public
        pure
        returns (uint size)
    {
        // Random number 1-100
        uint r = (randomBase % 100) + 1;

        // Probabilities:
        // 3x: 16%
        // 2x: 32%
        // else: 1x
        if (maxSize == 3) {
            if (r <= 20) {
                return 3;
            } else if (r <= 35) {
                return 2;
            } else {
                return 1;
            }
        } else {
            // Probabilities:
            // 2x: 30%
            // else: 1x
            if (r <= 30) {
                return 2;
            } else {
                return 1;
            }
        }
    }

    // Generate token URI
    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Balls of Art #',
                                    uint2str(tokenId),
                                    '", "description": "Balls of Art are an assortment of 111 fully on-chain, randomly generated, happy art balls", "attributes": "", "image":"data:image/svg+xml;base64,',
                                    Base64.encode(bytes(generateFinalSvg())),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    // Mint new Balls of Art
    function mintBallsOfArt(uint tokenId) public payable {
        // Make sure the amount of ETH is equal or larger than the minimum mint price
        require(msg.value >= mintPrice, "Not enough ETH sent");

        // Mint token
        _mint(msg.sender, tokenId);

        // Increase minted tokens counter
        ++totalSupply;

        emit BallsCreated(tokenId);
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
