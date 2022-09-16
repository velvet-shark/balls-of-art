//SPDX-License-Identifier: MIT
// @title    Balls of Art
// @version  1.0.0
// @author   Radek Sienkiewicz | velvetshark.com
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract BallsOfArt is ERC721, Ownable {
    // Ball parameters
    struct Ball {
        uint256 x; // x coordinates of the top left corner
        uint256 y; // y coordinates of the top left corner
        uint256 width;
        uint256 height;
        string fill; // ball color
        uint256 randomBase;
    }

    string[7] internal backgroundColors = [
        "#ffffff",
        "#F1F1F1",
        "#F7ECDE",
        "#EEF6FF",
        "#FCF8E8",
        "#FFF9D7",
        "#F9F2ED"
    ];
    string[23] internal ballColors = [
        "#00ff00",
        "#ff0000",
        "#0000ff",
        "#367E18",
        "#F57328",
        "#CC3636",
        "#D800A6",
        "#400D51",
        "#31E1F7",
        "#FA7070",
        "#A1C298",
        "#8758FF",
        "#F07DEA",
        "#25316D",
        "#3D8361",
        "#FECD70",
        "#FFC4C4",
        "#C3FF99",
        "#F94892",
        "#FF7F3F",
        "#2A0944",
        "#3330E4",
        "#F637EC"
    ];

    uint256 public maxSupply = 111; // max number of tokens
    uint256 public mintedTokens = 0; // number of tokens minted

    // Events
    event BallCreated(uint256 indexed tokenId, string tokenURI);

    constructor() ERC721("Balls of Art", "BART") {}

    // Functions
    function createBallStruct(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        uint256 randomBase
    ) public view returns (Ball memory) {
        return
            Ball({
                x: x,
                y: y,
                width: width,
                height: height,
                fill: ballColors[(randomBase % 21)], // Choose random color from backgroundColors array. TODO: Change to 50 (size of bgcolors array)
                randomBase: randomBase
            });
    }

    function ballSvg(Ball memory ball) public pure returns (bytes memory) {
        return
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
            );
    }

    // Generate SVG code for a single line
    function generateLineSvg(uint256 lineNumber, uint256 randomBase)
        public
        view
        returns (bytes memory)
    {
        // Line SVG
        bytes memory lineSvg = "";

        uint256 y = 150; // Default y for row 1
        if (lineNumber == 2) {
            y = 475; // Default y for row 2
        } else if (lineNumber == 3) {
            y = 800; // Default y for row 3
        }

        // Size of ball at slot 1
        uint256 ballSize11 = drawBallSize(3, randomBase);
        console.log("Ball size 1: ", ballSize11);

        // Ball size 1x? Paint 1x at slot 1
        if (ballSize11 == 1) {
            Ball memory ball11 = createBallStruct(150, y, 300, 300, randomBase);
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11));

            // Slot 2
            // Size of ball at slot 2
            uint256 ballSize12 = drawBallSize(2, randomBase >> 2);
            console.log("Ball size 2: ", ballSize12);

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
                lineSvg = bytes.concat(
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
                lineSvg = bytes.concat(lineSvg, ballSvg(ball12));
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
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11), ballSvg(ball13));

            // Ball size 3x? Paint 3x at slot 1
        } else if (ballSize11 == 3) {
            Ball memory ball11 = createBallStruct(
                150,
                y,
                950,
                300,
                randomBase >> 14
            );
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11));
        }

        return lineSvg;
    }

    // Generate final SVG code for the NFT
    function generateFinalSvg() public view returns (bytes memory) {
        uint randomBase1 = uint(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        uint randomBase2 = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        uint randomBase3 = uint(
            keccak256(abi.encodePacked(msg.sender, block.timestamp))
        );

        bytes memory backgroundCode = abi.encodePacked(
            '<rect width="1250" height="1250" fill="',
            backgroundColors[(randomBase1 % 7)],
            '" />'
        );

        // SVG opening and closing tags, background color + 3 lines generated
        bytes memory finalSvg = bytes.concat(
            abi.encodePacked(
                '<svg viewBox="0 0 1250 1250" xmlns="http://www.w3.org/2000/svg">',
                backgroundCode,
                generateLineSvg(1, randomBase1),
                generateLineSvg(2, randomBase2),
                generateLineSvg(3, randomBase3),
                abi.encodePacked("</svg>")
            )
        );

        console.log("Final Svg: ", string(finalSvg));
        return finalSvg;
    }

    function drawBallSize(uint256 maxSize, uint256 randomBase)
        public
        pure
        returns (uint256 size)
    {
        // Random number 1-100
        uint256 r = (randomBase % 100) + 1;

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

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
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
