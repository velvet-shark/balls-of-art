//SPDX-License-Identifier: MIT
// @title    Balls of Art
// @version  1.0.0
// @author   Radek Sienkiewicz | velvetshark.com
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

    string[] internal backgroundColors = ["#ffffff", "#fafafa"];
    string[] internal ballColors = ["#00ff00", "#ff0000", "#0000ff"];

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
                fill: backgroundColors[(randomBase % 50)], // Choose random color from backgroundColors array
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
                uint2str(ball.x + 150),
                " ",
                uint2str(ball.y + ball.height - 50),
                " A 100 100 0 0 0 ",
                uint2str(ball.x + ball.width - 50),
                " ",
                uint2str(ball.y + ball.height - 150),
                '" />'
            );
    }

    // TODO review all randomBases and shift accordingly
    function generateLineSvg(uint256 lineNumber)
        public
        view
        returns (bytes memory)
    {
        // A base for all "random" values
        uint256 randomBase = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1)))
        );
        // Final SVG
        bytes memory lineSvg = "";

        uint256 y = 150; // Default y for row 1
        if (lineNumber == 2) {
            y = 475; // Default y for row 2
        } else if (lineNumber == 3) {
            y = 800; // Default y for row 3
        }

        // Size of ball at slot 1
        uint256 ballSize11 = drawBallSize(3, randomBase);

        // Ball size 1x? Paint 1x at slot 1
        if (ballSize11 == 1) {
            Ball memory ball11 = createBallStruct(150, y, 300, 300, randomBase);
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11));

            // Slot 2
            // Size of ball at slot 2
            uint256 ballSize12 = drawBallSize(3, randomBase);

            // Ball size 1x? Paint 1x at slot 2 and 1x at slot 3
            if (ballSize12 == 1) {
                Ball memory ball12 = createBallStruct(
                    475,
                    y,
                    300,
                    300,
                    randomBase >> 1
                );
                Ball memory ball13 = createBallStruct(
                    800,
                    y,
                    300,
                    300,
                    randomBase >> 2
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
                    randomBase
                );
                lineSvg = bytes.concat(lineSvg, ballSvg(ball12));
            }

            // Ball size 2x? Paint 2x at slot 1 and 1x at slot 3
        } else if (ballSize11 == 2) {
            Ball memory ball11 = createBallStruct(150, y, 300, 625, randomBase);
            Ball memory ball13 = createBallStruct(
                800,
                y,
                300,
                300,
                randomBase >> 1
            );
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11), ballSvg(ball13));

            // Ball size 3x? Paint 3x at slot 1
        } else if (ballSize11 == 3) {
            Ball memory ball11 = createBallStruct(150, y, 950, 300, randomBase);
            lineSvg = bytes.concat(lineSvg, ballSvg(ball11));
        }
    }

    function drawBallSize(uint256 maxSize, uint256 randomBase)
        public
        pure
        returns (uint256 size)
    {
        return size = (randomBase % maxSize) + 1;
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
