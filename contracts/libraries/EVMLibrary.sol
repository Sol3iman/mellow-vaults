// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Library for emulating evm scripts
contract EVMLibrary {
    function execute(bytes memory code, bytes memory data) internal view returns (uint256 res) {
        uint16 pc;
        uint8 top;
        uint256[] memory stack = new uint256[](16);
        while (pc < code.length) {
            (pc, top, res) = _doInstruction(code, data, stack, pc, top);
            // type(uint256).max means execution continues
            if (res != type(uint256).max) {
                return res;
            }
        }
        return 0;
    }

    function _doInstruction(
        bytes memory code,
        bytes memory data,
        uint256[] memory stack,
        uint16 pc,
        uint8 top
    )
        private
        view
        returns (
            uint16 pcUpdated,
            uint8 topUpdated,
            uint256 res
        )
    {
        res = type(uint256).max;
        uint8 instruction = uint8(code[pc]);
        if (instruction == 0) {
            return (pc + 1, top, 0);
        }
        if (instruction < 0x10) {
            // ADD
            if (instruction == 0x1) {
                stack[top - 2] = stack[top - 1] + stack[top - 2];
            }
            // MUL
            else if (instruction == 0x2) {
                stack[top - 2] = stack[top - 1] * stack[top - 2];
            }
            // SUB
            else if (instruction == 0x3) {
                stack[top - 2] = stack[top - 1] - stack[top - 2];
            }
            // DIV
            else if (instruction == 0x4) {
                stack[top - 2] = stack[top - 1] / stack[top - 2];
            }
            // MOD
            else if (instruction == 0x6) {
                stack[top - 2] = stack[top - 1] % stack[top - 2];
            }
            stack[top - 1] = 0;
            pc += 1;
            top -= 1;
            return (pc, top, res);
        }
        if (instruction < 0x19) {
            // LT
            if (instruction == 0x10) {
                stack[top - 2] = stack[top - 1] < stack[top - 2] ? 1 : 0;
            }
            // GT
            else if (instruction == 0x11) {
                stack[top - 2] = stack[top - 1] > stack[top - 2] ? 1 : 0;
            }
            // EQ
            else if (instruction == 0x14) {
                stack[top - 2] = stack[top - 1] == stack[top - 2] ? 1 : 0;
            }
            // AND
            else if (instruction == 0x16) {
                stack[top - 2] = stack[top - 1] & stack[top - 2];
            }
            // OR
            else if (instruction == 0x17) {
                stack[top - 2] = stack[top - 1] | stack[top - 2];
            }
            // XOR
            else if (instruction == 0x18) {
                stack[top - 2] = stack[top - 1] ^ stack[top - 2];
            }

            stack[top - 1] = 0;
            pc += 1;
            top -= 1;
            stack[top] = 0;
            return (pc, top, res);
        }
        if (instruction == 0x19) {
            stack[top - 1] = ~stack[top - 1];
            pc += 1;
            return (pc, top, res);
        }
        if (instruction < 0x30) {
            // SHL
            if (instruction == 0x1B) {
                stack[top - 2] = stack[top - 2] << stack[top - 1];
            }
            // SHR
            else if (instruction == 0x1C) {
                stack[top - 2] = stack[top - 2] << stack[top - 1];
                // SHA 3
            } else if (instruction == 0x20) {
                uint256 kck;
                uint256 offset = stack[top - 1];
                uint256 length = stack[top - 2];
                assembly {
                    let off := add(add(data, 0x20), offset)
                    kck := keccak256(off, length)
                }
                stack[top - 2] = kck;
            }
            stack[top - 1] = 0;
            pc += 1;
            top -= 1;
            stack[top] = 0;
            return (pc, top, res);
        }
        if (instruction < 0x50) {
            // ADDRESS
            if (instruction == 0x30) {
                stack[top] = uint256(uint160(address(this)));
                // ORIGIN
            } else if (instruction == 0x32) {
                stack[top] = uint256(uint160(tx.origin));
                // CALLER
            } else if (instruction == 0x33) {
                stack[top] = uint256(uint160(msg.sender));
            }
            // TIMESTAMP
            else if (instruction == 0x42) {
                stack[top] = uint256(uint160(block.timestamp));
                // NUMBER
            } else if (instruction == 0x43) {
                stack[top] = uint256(uint160(block.number));
                // NUMBER
            } else if (instruction == 0x46) {
                uint256 chain;
                assembly {
                    chain := chainid()
                }
                stack[top] = chain;
            }
            pc += 1;
            top += 1;
            return (pc, top, res);
        }
        if (instruction < 0x60) {
            // POP
            if (instruction == 0x50) {
                top -= 1;
            }
            // MLOAD
            else if (instruction == 0x51) {
                uint256 val;
                uint256 offset = stack[top];
                assembly {
                    val := mload(add(add(data, 0x20), offset))
                }
                stack[top] = val;
                pc += 1;
            }
            // SLOAD
            else if (instruction == 0x54) {
                uint256 val;
                uint256 offset = stack[top];
                assembly {
                    val := sload(add(add(data, 0x20), offset))
                }
                stack[top] = val;
                pc += 1;
            }
            // JUMP
            else if (instruction == 0x56) {
                pc = uint16(stack[top - 1]);
                stack[top] = 0;
                top -= 1;
            }
            // JUMPI
            else if (instruction == 0x57) {
                pc = stack[top - 2] > 0 ? uint16(stack[top - 1]) : pc + 1;
                stack[top - 1] = 0;
                stack[top - 2] = 0;
                top -= 2;
            }

            return (pc, top, res);
        }
        // PUSHX
        if (instruction < 0x80) {
            uint8 len = (instruction - 0x60 + 1) * 8;
            uint256 slot;
            uint256 pc1 = pc;
            assembly {
                // mload 32 bytes shortly after the pc counter
                slot := mload(add(add(code, 0x21), pc1))
            }
            slot = slot >> (256 - len);
            stack[top] = slot;
            top += 1;
            pc += 1 + len / 8;
            return (pc, top, res);
        }
        // DUPX
        if (instruction < 0x90) {
            uint8 offset = (instruction - 0x80 + 1);
            stack[top] = stack[top - offset];
            top += 1;
            pc += 1;
            return (pc, top, res);
        }
        // SWAPX
        if (instruction < 0xA0) {
            uint8 offset = (instruction - 0x90 + 1);
            uint256 val = stack[top - offset - 1];
            stack[top - offset - 1] = stack[top - 1];
            stack[top - 1] = val;
            pc += 1;
            return (pc, top, res);
        }
    }
}
